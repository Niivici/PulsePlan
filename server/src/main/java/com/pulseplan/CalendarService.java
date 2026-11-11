package com.pulseplan;

import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
class CalendarService {
    private static final String BLOCK = "SELECT id, title, scene, color FROM event_blocks WHERE account_id = ?";
    private static final String SCHEDULE = """
        SELECT s.id, s.event_block_id, s.title, s.day_key, s.start_minute, s.end_minute, s.completed,
               b.scene, b.color
        FROM schedules s JOIN event_blocks b ON s.event_block_id = b.id
        WHERE s.account_id = ?
        """;

    private final JdbcClient jdbc;

    CalendarService(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    List<Block> blocks(long account) {
        return jdbc.sql(BLOCK + " ORDER BY id").param(account).query(Block.class).list();
    }

    Block block(long account, long id) {
        return jdbc.sql(BLOCK + " AND id = ?").params(account, id).query(Block.class).optional()
            .orElseThrow(CalendarService::notFound);
    }

    @Transactional
    public Block saveBlock(long account, Long id, BlockInput input) {
        lockAccount(account);
        Block before = id == null ? new Block(0, null, "", "#1687FF") : block(account, id);
        String title = required(Objects.requireNonNullElse(input.title(), Objects.toString(before.title(), "")), 120);
        String scene = Objects.requireNonNullElse(input.scene(), before.scene()).trim();
        String color = Objects.requireNonNullElse(input.color(), before.color());
        if (scene.length() > 120 || !color.matches("#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?")) {
            throw invalid("Invalid scene or color");
        }
        if (id == null) {
            id = insert(jdbc.sql("INSERT INTO event_blocks (account_id, title, scene, color) VALUES (?, ?, ?, ?)")
                .params(account, title, scene, color));
        } else {
            jdbc.sql("UPDATE event_blocks SET title = ?, scene = ?, color = ? WHERE account_id = ? AND id = ?")
                .params(title, scene, color, account, id).update();
        }
        return new Block(id, title, scene, color);
    }

    @Transactional
    public void deleteBlock(long account, long id) {
        lockAccount(account);
        block(account, id);
        if (jdbc.sql("SELECT COUNT(*) FROM schedules WHERE account_id = ? AND event_block_id = ?")
                .params(account, id).query(Long.class).single() > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Event block has schedules");
        }
        jdbc.sql("DELETE FROM event_blocks WHERE account_id = ? AND id = ?").params(account, id).update();
    }

    List<Schedule> schedules(long account, LocalDate from, LocalDate to) {
        if (!from.isBefore(to) || to.isAfter(from.plusYears(1))) {
            throw invalid("Invalid date range");
        }
        return jdbc.sql(SCHEDULE + " AND s.day_key >= ? AND s.day_key < ? ORDER BY s.day_key, s.start_minute, s.id")
            .params(account, from, to).query(Schedule.class).list();
    }

    Schedule schedule(long account, long id) {
        return jdbc.sql(SCHEDULE + " AND s.id = ?").params(account, id).query(Schedule.class).optional()
            .orElseThrow(CalendarService::notFound);
    }

    @Transactional
    public Schedule saveSchedule(long account, Long id, ScheduleInput input) {
        lockAccount(account);
        Schedule before = id == null ? null : schedule(account, id);
        Long blockId = input.eventBlockId();
        String title = input.title();
        LocalDate date = input.dayKey();
        Integer start = input.startMinute();
        Integer end = input.endMinute();
        Boolean completed = input.completed();
        if (before != null) {
            blockId = Objects.requireNonNullElse(blockId, before.eventBlockId());
            title = Objects.requireNonNullElse(title, before.title());
            date = Objects.requireNonNullElse(date, before.dayKey());
            start = Objects.requireNonNullElse(start, before.startMinute());
            end = Objects.requireNonNullElse(end, before.endMinute());
            completed = Objects.requireNonNullElse(completed, before.completed());
        }
        if (date == null || start == null || end == null || start < 0 || end > 1440 || start >= end) {
            throw invalid("Invalid schedule date, block or time");
        }
        title = required(title, 120);
        if (blockId != null) {
            block(account, blockId);
        }
        completed = Boolean.TRUE.equals(completed);
        var conflicts = jdbc.sql("""
            SELECT COUNT(*) FROM schedules
            WHERE account_id = ? AND day_key = ? AND start_minute < ? AND end_minute > ? AND id <> ?
            """).params(account, date, end, start, id == null ? 0L : id).query(Long.class).single();
        if (conflicts > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Schedule overlaps an existing item");
        }
        if (id == null) {
            if (blockId == null) {
                blockId = saveBlock(account, null, new BlockInput(title, null, null)).id();
            }
            id = insert(jdbc.sql("""
                INSERT INTO schedules (account_id, event_block_id, title, day_key, start_minute, end_minute, completed)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """).params(account, blockId, title, date, start, end, completed));
        } else {
            jdbc.sql("""
                UPDATE schedules SET event_block_id = ?, title = ?, day_key = ?, start_minute = ?, end_minute = ?, completed = ?
                WHERE account_id = ? AND id = ?
                """).params(blockId, title, date, start, end, completed, account, id).update();
        }
        return schedule(account, id);
    }

    @Transactional
    public void deleteSchedule(long account, long id) {
        lockAccount(account);
        if (jdbc.sql("DELETE FROM schedules WHERE account_id = ? AND id = ?").params(account, id).update() == 0) {
            throw notFound();
        }
    }

    List<Reminder> reminders(long account, long scheduleId) {
        schedule(account, scheduleId);
        return jdbc.sql("""
            SELECT r.id, r.schedule_id AS schedule_item_id, s.day_key, r.title, r.remind_minute AS "minute", r.intensity
            FROM reminders r JOIN schedules s ON s.id = r.schedule_id
            WHERE s.account_id = ? AND s.id = ? ORDER BY r.remind_minute, r.id
            """).params(account, scheduleId).query(Reminder.class).list();
    }

    @Transactional
    public List<Reminder> replaceReminders(long account, long scheduleId, List<ReminderInput> inputs) {
        lockAccount(account);
        schedule(account, scheduleId);
        if (inputs.size() > 20) {
            throw invalid("Too many reminders");
        }
        jdbc.sql("DELETE FROM reminders WHERE schedule_id = ?").param(scheduleId).update();
        for (ReminderInput input : inputs) {
            if (input == null || input.minute() == null || input.minute() < 0 || input.minute() >= 1440) {
                throw invalid("Invalid reminder minute");
            }
            jdbc.sql("INSERT INTO reminders (schedule_id, title, remind_minute, intensity) VALUES (?, ?, ?, ?)")
                .params(scheduleId, required(input.title(), 120), input.minute(), required(input.intensity(), 40)).update();
        }
        return reminders(account, scheduleId);
    }

    Overview overview(long account, LocalDate date) {
        var items = schedules(account, date, date.plusDays(1));
        var reminders = jdbc.sql("""
            SELECT r.id, r.schedule_id AS schedule_item_id, s.day_key, r.title, r.remind_minute AS "minute", r.intensity
            FROM reminders r JOIN schedules s ON s.id = r.schedule_id
            WHERE s.account_id = ? AND s.day_key = ? ORDER BY r.remind_minute, r.id
            """).params(account, date).query(Reminder.class).list();
        return new Overview(date, items, reminders);
    }

    Achievements achievements(long account) {
        return jdbc.sql("""
            SELECT COUNT(*) AS total,
                   COUNT(CASE WHEN completed THEN 1 END) AS completed,
                   COUNT(DISTINCT CASE WHEN completed THEN day_key END) AS active_days
            FROM schedules WHERE account_id = ?
            """).param(account).query(Achievements.class).single();
    }

    void lockAccount(long account) {
        jdbc.sql("SELECT id FROM accounts WHERE id = ? FOR UPDATE").param(account).query(Long.class).single();
    }

    private static long insert(JdbcClient.StatementSpec statement) {
        var key = new GeneratedKeyHolder();
        statement.update(key, "id");
        return Objects.requireNonNull(key.getKey()).longValue();
    }

    private static String required(String value, int maxLength) {
        String text = Objects.toString(value, "").trim();
        if (text.isEmpty() || text.length() > maxLength) {
            throw invalid("Invalid text field");
        }
        return text;
    }

    private static ResponseStatusException invalid(String reason) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, reason);
    }

    private static ResponseStatusException notFound() {
        return new ResponseStatusException(HttpStatus.NOT_FOUND, "Resource not found");
    }

    record Block(long id, String title, String scene, String color) {}
    record BlockInput(String title, String scene, String color) {}
    record Schedule(long id, long eventBlockId, String title, LocalDate dayKey, int startMinute,
                    int endMinute, boolean completed, String scene, String color) {}
    record ScheduleInput(Long eventBlockId, String title, LocalDate dayKey, Integer startMinute,
                         Integer endMinute, Boolean completed) {}
    record Reminder(long id, long scheduleItemId, LocalDate dayKey, String title, int minute, String intensity) {}
    record ReminderInput(String title, Integer minute, String intensity) {}
    record Overview(LocalDate date, List<Schedule> schedules, List<Reminder> reminders) {}
    record Achievements(long total, long completed, long activeDays) {}
}
