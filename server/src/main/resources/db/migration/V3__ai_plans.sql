CREATE TABLE ai_plans (
    id VARCHAR(36) PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    draft TEXT NOT NULL,
    confirmed TEXT,
    expires_at BIGINT NOT NULL
);

CREATE INDEX ai_plans_account_expiry ON ai_plans(account_id, expires_at);
