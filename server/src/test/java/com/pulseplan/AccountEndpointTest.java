package com.pulseplan;

import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
    "spring.datasource.url=jdbc:h2:mem:account-test;MODE=PostgreSQL;DB_CLOSE_DELAY=-1",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "pulseplan.admin.username=owner",
    "pulseplan.admin.password=Owner-test-password"
})
class AccountEndpointTest {
    @LocalServerPort
    private int port;
    private final HttpClient client = HttpClient.newHttpClient();
    private final JsonMapper json = new JsonMapper();

    @Test
    void publicRegistrationCreatesOnlyRegularUsers() throws Exception {
        var response = send("POST", "/auth/register", """
            {"username":"Alice","password":"Alice-test-password","role":"ADMIN"}
            """, null);
        assertThat(response.statusCode()).isEqualTo(201);
        assertThat(body(response).path("role").asText()).isEqualTo("USER");
        assertThat(body(response).has("password")).isFalse();
        assertThat(send("POST", "/auth/register", """
            {"username":"alice","password":"Other-test-password"}
            """, null).statusCode()).isEqualTo(409);
    }

    @Test
    void administratorCanLogInAndRevokeTheSession() throws Exception {
        assertThat(send("GET", "/me", null, null).statusCode()).isEqualTo(401);
        var credentials = """
            {"username":"owner","password":"Owner-test-password"}
            """;
        var login = send("POST", "/auth/login", credentials, null);
        assertThat(login.statusCode()).isEqualTo(200);
        var token = body(login).path("token").asText();
        assertThat(body(send("GET", "/me", null, token)).path("role").asText()).isEqualTo("ADMIN");
        assertThat(send("PATCH", "/me", """
            {"displayName":"管理员","timeZone":"Asia/Shanghai"}
            """, token).statusCode()).isEqualTo(200);
        assertThat(body(send("GET", "/me", null, token)).path("displayName").asText()).isEqualTo("管理员");
        assertThat(send("POST", "/auth/logout", null, token).statusCode()).isEqualTo(204);
        assertThat(send("GET", "/me", null, token).statusCode()).isEqualTo(401);
    }

    @Test
    void invalidCredentialsAndProfileAreRejected() throws Exception {
        assertThat(send("POST", "/auth/login", """
            {"username":"owner","password":"not-the-password"}
            """, null).statusCode()).isEqualTo(401);
        assertThat(send("POST", "/auth/register", """
            {"username":"invalid user","password":"short"}
            """, null).statusCode()).isEqualTo(400);
    }

    @Test
    void schedulesArePrivateAndRejectOverlap() throws Exception {
        var owner = loginNewUser("planner");
        var visitor = loginNewUser("visitor");
        var block = send("POST", "/event-blocks", """
            {"title":"Study","scene":"Focus","color":"#1687FF"}
            """, owner);
        assertThat(block.statusCode()).isEqualTo(201);
        long blockId = body(block).path("id").asLong();
        var input = """
            {"eventBlockId":%d,"title":"Read","dayKey":"2026-11-12","startMinute":540,"endMinute":600}
            """.formatted(blockId);
        var created = send("POST", "/schedules", input, owner);
        assertThat(created.statusCode()).isEqualTo(201);
        String path = "/schedules/" + body(created).path("id").asLong();
        assertThat(send("GET", path, null, visitor).statusCode()).isEqualTo(404);
        assertThat(send("PATCH", path, "{\"completed\":true}", visitor).statusCode()).isEqualTo(404);
        assertThat(send("POST", "/schedules", input, owner).statusCode()).isEqualTo(409);
        assertThat(send("POST", "/schedules", input.replace("600", "660").replace("540", "600"), owner)
            .statusCode()).isEqualTo(201);
        assertThat(send("PATCH", path, "{\"completed\":true}", owner).statusCode()).isEqualTo(200);
        assertThat(send("PUT", path + "/reminders", """
            [{"title":"Prepare","minute":530,"intensity":"normal"}]
            """, owner).statusCode()).isEqualTo(200);
        assertThat(body(send("GET", path + "/reminders", null, owner)).size()).isEqualTo(1);
        assertThat(body(send("GET", "/overview?date=2026-11-12", null, owner)).path("schedules").size()).isEqualTo(2);
        assertThat(body(send("GET", "/achievements", null, owner)).path("completed").asLong()).isEqualTo(1);
        assertThat(send("DELETE", path, null, owner).statusCode()).isEqualTo(204);
        assertThat(send("GET", path + "/reminders", null, owner).statusCode()).isEqualTo(404);
    }

    private static final AtomicReference<String> MODEL_REQUEST = new AtomicReference<>();
    private static final HttpServer MODEL = startModel();

    @DynamicPropertySource
    static void integrationConfiguration(DynamicPropertyRegistry settings) {
        String databaseUrl = System.getenv("PULSEPLAN_TEST_DB_URL");
        if (databaseUrl != null && !databaseUrl.isBlank()) {
            settings.add("spring.datasource.url", () -> databaseUrl);
            settings.add("spring.datasource.username", () -> System.getenv("PULSEPLAN_TEST_DB_USERNAME"));
            settings.add("spring.datasource.password", () -> System.getenv("PULSEPLAN_TEST_DB_PASSWORD"));
        }
        settings.add("pulseplan.ai.url", () -> "http://localhost:" + MODEL.getAddress().getPort() + "/chat/completions");
        settings.add("pulseplan.ai.key", () -> "integration-test-key");
        settings.add("pulseplan.ai.daily-account-limit", () -> "2");
    }

    @AfterAll
    static void stopModel() {
        MODEL.stop(0);
    }

    private static HttpServer startModel() {
        try {
            var server = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
            server.createContext("/chat/completions", exchange -> {
                MODEL_REQUEST.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
                var mapper = new JsonMapper();
                var content = """
                    {"title":"Focus plan","items":[{"title":"Read","dayKey":"2026-11-12","startMinute":540,"endMinute":600},{"title":"Review","dayKey":"2026-11-12","startMinute":620,"endMinute":650}]}
                    """;
                var payload = mapper.createObjectNode();
                var choice = payload.putArray("choices").addObject();
                choice.put("finish_reason", "stop").putObject("message").put("content", content);
                byte[] response = mapper.writeValueAsBytes(payload);
                exchange.sendResponseHeaders(200, response.length);
                try (var output = exchange.getResponseBody()) {
                    output.write(response);
                }
            });
            server.start();
            return server;
        } catch (java.io.IOException failure) {
            throw new IllegalStateException(failure);
        }
    }

    @Test
    void modelPreviewRequiresConfirmationAndCannotBeAppliedTwice() throws Exception {
        String token = loginNewUser("ai-planner");
        var preview = send("POST", "/ai/plans", """
            {"prompt":"Plan a study session","from":"2026-11-12","to":"2026-11-13"}
            """, token);
        assertThat(preview.statusCode()).isEqualTo(201);
        assertThat(json.readTree(MODEL_REQUEST.get()).path("model").asText()).isEqualTo("deepseek-v4-pro");
        String list = "/schedules?from=2026-11-12&to=2026-11-13";
        assertThat(body(send("GET", list, null, token))).isEmpty();
        String confirm = "/ai/plans/" + body(preview).path("id").asText() + "/confirm";
        assertThat(send("POST", confirm, null, loginNewUser("ai-visitor")).statusCode()).isEqualTo(404);
        var saved = send("POST", confirm, null, token);
        assertThat(saved.statusCode()).isEqualTo(200);
        assertThat(body(saved)).hasSize(2);
        assertThat(body(send("POST", confirm, null, token))).isEqualTo(body(saved));
        assertThat(body(send("GET", list, null, token))).hasSize(2);
    }

    @Test
    void stalePlanRollsBackEveryWriteWhenALaterSlotConflicts() throws Exception {
        String token = loginNewUser("ai-conflict");
        var preview = send("POST", "/ai/plans", """
            {"prompt":"Plan a study session","from":"2026-11-12","to":"2026-11-13"}
            """, token);
        assertThat(preview.statusCode()).isEqualTo(201);
        assertThat(send("POST", "/schedules", """
            {"title":"New appointment","dayKey":"2026-11-12","startMinute":620,"endMinute":645}
            """, token).statusCode()).isEqualTo(201);
        String confirm = "/ai/plans/" + body(preview).path("id").asText() + "/confirm";
        assertThat(send("POST", confirm, null, token).statusCode()).isEqualTo(409);
        var schedules = body(send("GET", "/schedules?from=2026-11-12&to=2026-11-13", null, token));
        assertThat(schedules).hasSize(1);
        assertThat(schedules.path(0).path("title").asText()).isEqualTo("New appointment");
        assertThat(body(send("GET", "/event-blocks", null, token))).hasSize(1);
    }

    @Test
    void aiQuotaRejectsExcessRequestsBeforeCallingTheProvider() throws Exception {
        String token = loginNewUser("ai-quota");
        String input = """
            {"prompt":"Quota test","from":"2026-11-12","to":"2026-11-13"}
            """;
        assertThat(send("POST", "/ai/plans", input, token).statusCode()).isEqualTo(201);
        assertThat(send("POST", "/ai/plans", input, token).statusCode()).isEqualTo(201);
        assertThat(send("POST", "/ai/plans", input.replace("Quota test", "Blocked test"), token).statusCode())
            .isEqualTo(429);
        assertThat(MODEL_REQUEST.get()).doesNotContain("Blocked test");
        assertThat(send("POST", "/ai/plans", input, loginNewUser("ai-quota-other")).statusCode()).isEqualTo(201);
    }

    private String loginNewUser(String username) throws Exception {
        String credentials = """
            {"username":"%s","password":"schedule-test-password"}
            """.formatted(username);
        assertThat(send("POST", "/auth/register", credentials, null).statusCode()).isEqualTo(201);
        return body(send("POST", "/auth/login", credentials, null)).path("token").asText();
    }

    private JsonNode body(HttpResponse<String> response) {
        return json.readTree(response.body());
    }

    private HttpResponse<String> send(String method, String path, String body, String token) throws Exception {
        var request = HttpRequest.newBuilder(URI.create("http://localhost:" + port + "/api/v1" + path));
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        request.header("Content-Type", "application/json");
        request.method(method, body == null ? HttpRequest.BodyPublishers.noBody() : HttpRequest.BodyPublishers.ofString(body));
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }
}
