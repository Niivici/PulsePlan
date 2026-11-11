package com.pulseplan;

import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/ai/plans")
class AiController {
    private final Accounts accounts;
    private final AiPlans plans;

    AiController(Accounts accounts, AiPlans plans) {
        this.accounts = accounts;
        this.plans = plans;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    AiPlans.Preview preview(@RequestHeader HttpHeaders headers, @RequestBody AiPlans.Request request) {
        return plans.generate(accounts.current(headers.getFirst(HttpHeaders.AUTHORIZATION)), request);
    }

    @PostMapping("/{id}/confirm")
    List<CalendarService.Schedule> confirm(@RequestHeader HttpHeaders headers, @PathVariable UUID id) {
        return plans.confirm(accounts.current(headers.getFirst(HttpHeaders.AUTHORIZATION)).id(), id);
    }
}
