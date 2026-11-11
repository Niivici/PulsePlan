package com.pulseplan;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.json.JsonMapper;

@Component
class DeepSeekClient {
    private static final String INSTRUCTIONS = """
        You are a scheduling assistant. Return a single JSON object, with this shape:
        {"title":"Project work","items":[{"title":"Write outline","dayKey":"2026-11-12","startMinute":540,"endMinute":600}]}.
        Use the language of the goal for titles. Propose at most 12 items within the requested date range,
        inclusive from and exclusive to. Treat the date range as available bounds, not a recurrence.
        Schedule a single task at one time exactly once unless the goal explicitly asks for repetition.
        All times are local minutes from midnight. Do not overlap busy
        slots or other proposed items. Use empty items if the goal cannot be scheduled.
        """;
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();
    private final JsonMapper json;
    private final URI endpoint;
    private final String model;
    private final String key;

    DeepSeekClient(JsonMapper json, @Value("${pulseplan.ai.url}") URI endpoint,
                   @Value("${pulseplan.ai.model}") String model, @Value("${pulseplan.ai.key}") String key) {
        this.json = json;
        this.endpoint = endpoint;
        this.model = model;
        this.key = key;
    }

    void requireConfigured() {
        if (key.isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "AI service is not configured");
        }
    }

    AiPlans.Proposal generate(AiPlans.Context context) {
        var payload = Map.of(
            "model", model,
            "response_format", Map.of("type", "json_object"),
            "thinking", Map.of("type", "disabled"),
            "max_tokens", 2500,
            "messages", List.of(Map.of("role", "system", "content", INSTRUCTIONS),
                Map.of("role", "user", "content", json.writeValueAsString(context))));
        var request = HttpRequest.newBuilder(endpoint).timeout(Duration.ofSeconds(45))
            .header("Authorization", "Bearer " + key).header("Content-Type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(payload))).build();
        try {
            var response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                throw upstream("AI provider rejected the request");
            }
            var choice = json.readTree(response.body()).path("choices").path(0);
            var content = choice.path("message").path("content");
            if (!"stop".equals(choice.path("finish_reason").asText()) || !content.isString() || content.asText().isBlank()) {
                throw upstream("AI provider returned incomplete output");
            }
            return json.readValue(content.asText(), AiPlans.Proposal.class);
        } catch (java.net.http.HttpTimeoutException failure) {
            throw new ResponseStatusException(HttpStatus.GATEWAY_TIMEOUT, "AI provider timed out");
        } catch (IOException | JacksonException failure) {
            throw upstream("AI provider returned an invalid response");
        } catch (InterruptedException failure) {
            Thread.currentThread().interrupt();
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "AI request was interrupted");
        }
    }

    private static ResponseStatusException upstream(String reason) {
        return new ResponseStatusException(HttpStatus.BAD_GATEWAY, reason);
    }
}
