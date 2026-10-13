-- Settlement reconciliation reads by status and date. Built CONCURRENTLY so
-- the migration does not hold a write lock on a live table.
CREATE INDEX CONCURRENTLY IF NOT EXISTS payment_status_created_at_idx
    ON payment (status, created_at DESC);
