-- Baseline schema. Written to be re-runnable, so a partial failure can be
-- retried without hand-editing the database.
CREATE TABLE IF NOT EXISTS payment (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    external_ref   text        NOT NULL,
    amount_cents   bigint      NOT NULL CHECK (amount_cents > 0),
    currency       char(3)     NOT NULL,
    status         text        NOT NULL DEFAULT 'pending',
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT payment_status_check
        CHECK (status IN ('pending', 'settled', 'failed', 'reversed'))
);

CREATE UNIQUE INDEX IF NOT EXISTS payment_external_ref_key
    ON payment (external_ref);
