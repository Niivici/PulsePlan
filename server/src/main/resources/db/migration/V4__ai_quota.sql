CREATE TABLE ai_daily_budget (
    singleton SMALLINT PRIMARY KEY CHECK (singleton = 1),
    usage_day DATE,
    attempts INTEGER NOT NULL CHECK (attempts >= 0)
);
INSERT INTO ai_daily_budget (singleton, attempts) VALUES (1, 0);

CREATE TABLE ai_account_usage (
    account_id BIGINT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    usage_day DATE NOT NULL,
    attempts INTEGER NOT NULL CHECK (attempts >= 0)
);
