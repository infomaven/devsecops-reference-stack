-- Append-only audit of status transitions. The application role can insert
-- but not update or delete; the grant lives in the Ansible role, not here.
CREATE TABLE IF NOT EXISTS payment_audit (
    id          bigserial PRIMARY KEY,
    payment_id  uuid        NOT NULL REFERENCES payment (id),
    from_status text,
    to_status   text        NOT NULL,
    actor       text        NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payment_audit_payment_id_idx
    ON payment_audit (payment_id);
