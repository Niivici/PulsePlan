package com.pulseplan;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Locale;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
class Accounts implements ApplicationRunner {
    private static final Duration SESSION_DURATION = Duration.ofDays(7);
    private final JdbcClient jdbc;
    private final String adminUsername;
    private final String adminPassword;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final SecureRandom random = new SecureRandom();
    private final String unknownAccountHash = passwordEncoder.encode("unused-account-placeholder");

    Accounts(JdbcClient jdbc, @Value("${pulseplan.admin.username}") String adminUsername,
             @Value("${pulseplan.admin.password}") String adminPassword) {
        this.jdbc = jdbc;
        this.adminUsername = adminUsername;
        this.adminPassword = adminPassword;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (adminUsername.isEmpty() && adminPassword.isEmpty()) {
            return;
        }
        if (hasAdministrator()) {
            return;
        }
        try {
            create(adminUsername, adminPassword, true);
        } catch (DuplicateKeyException conflict) {
            if (!hasAdministrator()) {
                throw new IllegalStateException("Configured administrator username is already registered", conflict);
            }
        }
    }

    Profile register(String username, String password) {
        try {
            return create(username, password, false);
        } catch (DuplicateKeyException conflict) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username is already registered");
        }
    }

    private Profile create(String username, String password, boolean admin) {
        String normalized = normalize(username);
        if (!normalized.matches("[a-z0-9_.-]{3,32}") || !validPassword(password)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid username or password");
        }
        jdbc.sql("""
            INSERT INTO accounts (username, password_hash, display_name, time_zone, admin_slot)
            VALUES (?, ?, ?, ?, ?)
            """).params(normalized, passwordEncoder.encode(password), username.trim(), "Asia/Shanghai",
                admin ? 1 : null).update();
        return byUsername(normalized).profile();
    }

    private boolean hasAdministrator() {
        return jdbc.sql("SELECT id FROM accounts WHERE admin_slot = 1").query(Long.class).optional().isPresent();
    }

    @Transactional
    public Login login(String username, String password) {
        if (!validPassword(password)) {
            throw unauthorized();
        }
        Account account = byUsername(normalize(username));
        String hash = account == null ? unknownAccountHash : account.passwordHash();
        if (!passwordEncoder.matches(password, hash) || account == null) {
            throw unauthorized();
        }

        byte[] secret = new byte[32];
        random.nextBytes(secret);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(secret);
        Instant now = Instant.now();
        Instant expiresAt = now.plus(SESSION_DURATION);
        jdbc.sql("DELETE FROM account_sessions WHERE expires_at <= ?").param(now.getEpochSecond()).update();
        jdbc.sql("INSERT INTO account_sessions (token_hash, account_id, expires_at) VALUES (?, ?, ?)")
            .params(digest(token), account.profile().id(), expiresAt.getEpochSecond()).update();
        return new Login(token, expiresAt, account.profile());
    }

    Profile current(String authorization) {
        return jdbc.sql("""
            SELECT a.id, a.username, a.display_name, a.time_zone, a.admin_slot
            FROM accounts a JOIN account_sessions s ON a.id = s.account_id
            WHERE s.token_hash = ? AND s.expires_at > ?
            """).params(sessionHash(authorization), Instant.now().getEpochSecond())
            .query((row, index) -> new Profile(row.getLong("id"), row.getString("username"),
                row.getString("display_name"), row.getString("time_zone"), row.getObject("admin_slot") == null ? "USER" : "ADMIN"))
            .optional().orElseThrow(Accounts::unauthorized);
    }

    Profile update(Profile current, String displayName, String timeZone) {
        if (displayName == null && timeZone == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Provide a display name or time zone");
        }
        String name = displayName == null ? current.displayName() : displayName.trim();
        String zone = timeZone == null ? current.timeZone() : timeZone;
        if (name.isEmpty() || name.length() > 64 || !ZoneId.getAvailableZoneIds().contains(zone)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid display name or time zone");
        }
        jdbc.sql("""
            UPDATE accounts
            SET display_name = COALESCE(?, display_name), time_zone = COALESCE(?, time_zone)
            WHERE id = ?
            """).params(displayName == null ? null : name, timeZone == null ? null : zone, current.id()).update();
        return byUsername(current.username()).profile();
    }

    void logout(String authorization) {
        current(authorization);
        jdbc.sql("DELETE FROM account_sessions WHERE token_hash = ?").param(sessionHash(authorization)).update();
    }

    private Account byUsername(String username) {
        return jdbc.sql("""
            SELECT id, username, password_hash, display_name, time_zone, admin_slot FROM accounts WHERE username = ?
            """).param(username).query((row, index) -> new Account(
                new Profile(row.getLong("id"), row.getString("username"), row.getString("display_name"),
                    row.getString("time_zone"), row.getObject("admin_slot") == null ? "USER" : "ADMIN"),
                row.getString("password_hash"))).optional().orElse(null);
    }

    private static String normalize(String username) {
        return username == null ? "" : username.trim().toLowerCase(Locale.ROOT);
    }

    private static boolean validPassword(String password) {
        return password != null && password.length() >= 8 && password.length() <= 72
            && password.indexOf(0) < 0 && password.getBytes(StandardCharsets.UTF_8).length <= 72;
    }

    private static String sessionHash(String authorization) {
        if (authorization == null || !authorization.matches("(?i)Bearer [A-Za-z0-9_-]{43}")) {
            throw unauthorized();
        }
        return digest(authorization.substring(7));
    }

    private static String digest(String token) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.US_ASCII)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(exception);
        }
    }

    private static ResponseStatusException unauthorized() {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials or session");
    }

    record Profile(long id, String username, String displayName, String timeZone, String role) {}
    record Login(String token, Instant expiresAt, Profile user) {}
    private record Account(Profile profile, String passwordHash) {}
}
