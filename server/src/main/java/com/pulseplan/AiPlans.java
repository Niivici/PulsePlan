package com.pulseplan;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

@Service
class AiPlans {
    private final JdbcClient jdbc;
    private final JsonMapper json;
    private final CalendarService calendar;
    private final DeepSeekClient model;
    private final AiQuota quota;

    AiPlans(JdbcClient jdbc, JsonMapper json, CalendarService calendar, DeepSeekClient model, AiQuota quota) {
        this.jdbc = jdbc;
        this.json = json;
        this.calendar = calendar;
        this.model = model;
        this.quota = quota;
    }

    Preview generate(Accounts.Profile account, Request request) {
        var from = request.from() == null ? LocalDate.now(ZoneId.of(account.timeZone())) : request.from();
        var to = request.to() == null ? from.plusDays(7) : request.to();
        if (request.prompt() == null || request.prompt().isBlank() || request.prompt().length() > 2000
            || !from.isBefore(to) || to.isAfter(from.plusDays(14))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid goal or plan date range");
        }
        var busy = new ArrayList<>(calendar.schedules(account.id(), from, to).stream()
            .map(item -> new Slot(item.dayKey(), item.startMinute(), item.endMinute())).toList());
        model.requireConfigured();
        quota.reserve(account.id());
        var proposal = model.generate(new Context(request.prompt().trim(), account.timeZone(), from, to, busy));
        if (proposal == null || !validTitle(proposal.title()) || proposal.items() == null || proposal.items().size() > 12) {
            throw invalidProposal();
        }
        for (Item item : proposal.items()) {
            if (item == null || !validTitle(item.title()) || item.dayKey() == null || item.dayKey().isBefore(from)
                || !item.dayKey().isBefore(to) || item.startMinute() == null || item.endMinute() == null
                || item.startMinute() < 0 || item.endMinute() > 1440 || item.startMinute() >= item.endMinute()) {
                throw invalidProposal();
            }
            var slot = new Slot(item.dayKey(), item.startMinute(), item.endMinute());
            if (busy.stream().anyMatch(existing -> overlaps(existing, slot))) {
                throw invalidProposal();
            }
            busy.add(slot);
        }
        if (proposal.items().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "No available schedule was proposed");
        }
        String id = UUID.randomUUID().toString();
        Instant now = Instant.now();
        Instant expires = now.plus(Duration.ofHours(24));
        jdbc.sql("DELETE FROM ai_plans WHERE account_id = ? AND confirmed IS NULL AND expires_at <= ?")
            .params(account.id(), now.getEpochSecond()).update();
        jdbc.sql("INSERT INTO ai_plans (id, account_id, draft, expires_at) VALUES (?, ?, ?, ?)")
            .params(id, account.id(), json.writeValueAsString(proposal), expires.getEpochSecond()).update();
        return new Preview(id, proposal.title(), proposal.items(), expires);
    }

    @Transactional
    public List<CalendarService.Schedule> confirm(long account, UUID id) {
        calendar.lockAccount(account);
        var stored = jdbc.sql("SELECT draft, confirmed, expires_at FROM ai_plans WHERE account_id = ? AND id = ?")
            .params(account, id.toString()).query(Stored.class).optional()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Plan not found"));
        if (stored.confirmed() != null) {
            return json.readValue(stored.confirmed(), new TypeReference<List<CalendarService.Schedule>>() {});
        }
        if (stored.expiresAt() <= Instant.now().getEpochSecond()) {
            throw new ResponseStatusException(HttpStatus.GONE, "Plan has expired");
        }
        var proposal = json.readValue(stored.draft(), Proposal.class);
        var block = calendar.saveBlock(account, null, new CalendarService.BlockInput(proposal.title(), null, null));
        var saved = new ArrayList<CalendarService.Schedule>();
        for (Item item : proposal.items()) {
            saved.add(calendar.saveSchedule(account, null, new CalendarService.ScheduleInput(
                block.id(), item.title(), item.dayKey(), item.startMinute(), item.endMinute(), false)));
        }
        jdbc.sql("UPDATE ai_plans SET confirmed = ? WHERE account_id = ? AND id = ?")
            .params(json.writeValueAsString(saved), account, id.toString()).update();
        return saved;
    }

    private static boolean overlaps(Slot a, Slot b) {
        return a.dayKey().equals(b.dayKey()) && a.startMinute() < b.endMinute() && b.startMinute() < a.endMinute();
    }

    private static boolean validTitle(String title) {
        return title != null && !title.isBlank() && title.length() <= 120;
    }

    private static ResponseStatusException invalidProposal() {
        return new ResponseStatusException(HttpStatus.BAD_GATEWAY, "AI provider proposed an invalid schedule");
    }

    record Request(String prompt, LocalDate from, LocalDate to) {}
    record Context(String goal, String timeZone, LocalDate from, LocalDate to, List<Slot> busy) {}
    record Slot(LocalDate dayKey, int startMinute, int endMinute) {}
    record Proposal(String title, List<Item> items) {}
    record Item(String title, LocalDate dayKey, Integer startMinute, Integer endMinute) {}
    record Preview(String id, String title, List<Item> items, Instant expiresAt) {}
    record Stored(String draft, String confirmed, long expiresAt) {}
}
