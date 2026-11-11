package com.pulseplan;

import java.time.LocalDate;
import java.time.ZoneOffset;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
class AiQuota {
    private final JdbcClient jdbc;
    private final int perAccount;
    private final int global;

    AiQuota(JdbcClient jdbc, @Value("${pulseplan.ai.daily-account-limit}") int perAccount,
            @Value("${pulseplan.ai.daily-global-limit}") int global) {
        if (perAccount < 1 || global < 1) {
            throw new IllegalArgumentException("AI daily limits must be positive");
        }
        this.jdbc = jdbc;
        this.perAccount = perAccount;
        this.global = global;
    }

    @Transactional
    public void reserve(long accountId) {
        Usage budget = jdbc.sql("""
            SELECT usage_day, attempts FROM ai_daily_budget WHERE singleton = 1 FOR UPDATE
            """).query(Usage.class).single();
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        int globalUsed = budget.on(today);
        if (globalUsed >= global) {
            throw limited();
        }
        var usage = jdbc.sql("SELECT usage_day, attempts FROM ai_account_usage WHERE account_id = ?")
            .param(accountId).query(Usage.class).optional();
        int accountUsed = usage.map(value -> value.on(today)).orElse(0);
        if (accountUsed >= perAccount) {
            throw limited();
        }
        if (usage.isPresent()) {
            jdbc.sql("UPDATE ai_account_usage SET usage_day = ?, attempts = ? WHERE account_id = ?")
                .params(today, accountUsed + 1, accountId).update();
        } else {
            jdbc.sql("INSERT INTO ai_account_usage (account_id, usage_day, attempts) VALUES (?, ?, 1)")
                .params(accountId, today).update();
        }
        jdbc.sql("UPDATE ai_daily_budget SET usage_day = ?, attempts = ? WHERE singleton = 1")
            .params(today, globalUsed + 1).update();
    }

    private static ResponseStatusException limited() {
        return new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "Daily AI scheduling quota exhausted");
    }

    record Usage(LocalDate usageDay, int attempts) {
        int on(LocalDate day) {
            return day.equals(usageDay) ? attempts : 0;
        }
    }
}
