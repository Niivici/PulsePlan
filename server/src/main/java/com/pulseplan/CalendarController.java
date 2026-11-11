package com.pulseplan;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import com.pulseplan.CalendarService.Achievements;
import com.pulseplan.CalendarService.Block;
import com.pulseplan.CalendarService.BlockInput;
import com.pulseplan.CalendarService.Overview;
import com.pulseplan.CalendarService.Reminder;
import com.pulseplan.CalendarService.ReminderInput;
import com.pulseplan.CalendarService.Schedule;
import com.pulseplan.CalendarService.ScheduleInput;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
class CalendarController {
    private final Accounts accounts;
    private final CalendarService calendar;

    CalendarController(Accounts accounts, CalendarService calendar) {
        this.accounts = accounts;
        this.calendar = calendar;
    }

    @GetMapping("/event-blocks")
    List<Block> blocks(@RequestHeader HttpHeaders headers) {
        return calendar.blocks(owner(headers));
    }

    @PostMapping("/event-blocks")
    @ResponseStatus(HttpStatus.CREATED)
    Block createBlock(@RequestHeader HttpHeaders headers, @RequestBody BlockInput input) {
        return calendar.saveBlock(owner(headers), null, input);
    }

    @GetMapping("/event-blocks/{id}")
    Block block(@RequestHeader HttpHeaders headers, @PathVariable long id) {
        return calendar.block(owner(headers), id);
    }

    @PatchMapping("/event-blocks/{id}")
    Block updateBlock(@RequestHeader HttpHeaders headers, @PathVariable long id, @RequestBody BlockInput input) {
        return calendar.saveBlock(owner(headers), id, input);
    }

    @DeleteMapping("/event-blocks/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void deleteBlock(@RequestHeader HttpHeaders headers, @PathVariable long id) {
        calendar.deleteBlock(owner(headers), id);
    }

    @GetMapping("/schedules")
    List<Schedule> schedules(@RequestHeader HttpHeaders headers, @RequestParam LocalDate from, @RequestParam LocalDate to) {
        return calendar.schedules(owner(headers), from, to);
    }

    @PostMapping("/schedules")
    @ResponseStatus(HttpStatus.CREATED)
    Schedule createSchedule(@RequestHeader HttpHeaders headers, @RequestBody ScheduleInput input) {
        return calendar.saveSchedule(owner(headers), null, input);
    }

    @GetMapping("/schedules/{id}")
    Schedule schedule(@RequestHeader HttpHeaders headers, @PathVariable long id) {
        return calendar.schedule(owner(headers), id);
    }

    @PatchMapping("/schedules/{id}")
    Schedule updateSchedule(@RequestHeader HttpHeaders headers, @PathVariable long id, @RequestBody ScheduleInput input) {
        return calendar.saveSchedule(owner(headers), id, input);
    }

    @DeleteMapping("/schedules/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void deleteSchedule(@RequestHeader HttpHeaders headers, @PathVariable long id) {
        calendar.deleteSchedule(owner(headers), id);
    }

    @GetMapping("/schedules/{id}/reminders")
    List<Reminder> reminders(@RequestHeader HttpHeaders headers, @PathVariable long id) {
        return calendar.reminders(owner(headers), id);
    }

    @PutMapping("/schedules/{id}/reminders")
    List<Reminder> replaceReminders(@RequestHeader HttpHeaders headers, @PathVariable long id, @RequestBody List<ReminderInput> input) {
        return calendar.replaceReminders(owner(headers), id, input);
    }

    @GetMapping("/overview")
    Overview overview(@RequestHeader HttpHeaders headers, @RequestParam(required = false) LocalDate date) {
        var user = accounts.current(headers.getFirst(HttpHeaders.AUTHORIZATION));
        LocalDate target = date == null ? LocalDate.now(ZoneId.of(user.timeZone())) : date;
        return calendar.overview(user.id(), target);
    }

    @GetMapping("/achievements")
    Achievements achievements(@RequestHeader HttpHeaders headers) {
        return calendar.achievements(owner(headers));
    }

    private long owner(HttpHeaders headers) {
        return accounts.current(headers.getFirst(HttpHeaders.AUTHORIZATION)).id();
    }
}
