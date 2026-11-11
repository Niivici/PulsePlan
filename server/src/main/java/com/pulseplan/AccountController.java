package com.pulseplan;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
class AccountController {
    private final Accounts accounts;

    AccountController(Accounts accounts) {
        this.accounts = accounts;
    }

    @PostMapping("/auth/register")
    @ResponseStatus(HttpStatus.CREATED)
    Accounts.Profile register(@RequestBody Credentials credentials) {
        return accounts.register(credentials.username(), credentials.password());
    }

    @PostMapping("/auth/login")
    Accounts.Login login(@RequestBody Credentials credentials) {
        return accounts.login(credentials.username(), credentials.password());
    }

    @PostMapping("/auth/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void logout(@RequestHeader(name = "Authorization", required = false) String authorization) {
        accounts.logout(authorization);
    }

    @GetMapping("/me")
    Accounts.Profile current(@RequestHeader(name = "Authorization", required = false) String authorization) {
        return accounts.current(authorization);
    }

    @PatchMapping("/me")
    Accounts.Profile update(@RequestHeader(name = "Authorization", required = false) String authorization,
                            @RequestBody ProfileUpdate update) {
        return accounts.update(accounts.current(authorization), update.displayName(), update.timeZone());
    }

    record Credentials(String username, String password) {}
    record ProfileUpdate(String displayName, String timeZone) {}
}
