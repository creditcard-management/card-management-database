-- =============================================
-- Migration: V3
-- Description: card state transitions (card-lifecycle), credit limit history (card-limits)
--              and card audit
-- =============================================

-- ==========================================
-- STATE TRANSITIONS (card-lifecycle)
-- ==========================================
CREATE TABLE state_transitions (
    id BIGSERIAL PRIMARY KEY,
    card_id VARCHAR(36) NOT NULL,
    from_state VARCHAR(20),
    to_state VARCHAR(20) NOT NULL,
    event VARCHAR(50) NOT NULL,
    reason TEXT,
    performed_by VARCHAR(100) NOT NULL,
    transitioned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    successful BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    metadata TEXT,
    -- card-lifecycle registra las transiciones exitosas consumiendo los eventos card.* (at-least-once):
    -- el eventId del mensaje identifica cada fila y evita registrarla dos veces. NULL en las fallidas.
    event_id VARCHAR(36),

    CONSTRAINT fk_state_transitions_card
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX idx_state_transitions_card_id ON state_transitions(card_id, transitioned_at DESC);
CREATE INDEX idx_state_transitions_event ON state_transitions(event, transitioned_at DESC);
CREATE INDEX idx_state_transitions_successful ON state_transitions(successful, transitioned_at DESC);
CREATE INDEX idx_state_transitions_performed_by ON state_transitions(performed_by, transitioned_at DESC);
CREATE INDEX idx_state_transitions_metadata ON state_transitions (metadata DESC);

-- Una sola transición CREATE por tarjeta (consumo idempotente de card.created)
CREATE UNIQUE INDEX uq_state_transitions_create ON state_transitions (card_id)
    WHERE event = 'CREATE';

-- Varios NULL permitidos; un mismo evento, una sola fila
CREATE UNIQUE INDEX uq_state_transitions_event_id ON state_transitions (event_id);

COMMENT ON TABLE state_transitions IS 'Historial de transiciones de estado de tarjetas';
COMMENT ON COLUMN state_transitions.event_id IS 'eventId del evento card.* que originó la transición (NULL en fallidas)';

-- ==========================================
-- CREDIT LIMIT HISTORY (card-limits)
-- ==========================================
CREATE TABLE credit_limit_history (
    id BIGSERIAL PRIMARY KEY,
    credit_limit_id VARCHAR(36) NOT NULL,
    limit_type VARCHAR(20) NOT NULL,
    action VARCHAR(20) NOT NULL,
    previous_value_amount NUMERIC(15,2),
    previous_value_currency VARCHAR(3),
    new_value_amount NUMERIC(15,2),
    new_value_currency VARCHAR(3),
    difference_amount NUMERIC(15,2),
    difference_currency VARCHAR(3),
    reason VARCHAR(500),
    changed_by VARCHAR(100) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    successful BOOLEAN NOT NULL DEFAULT true,
    error_message VARCHAR(500),
    metadata TEXT,

    CONSTRAINT fk_history_credit_limit
        FOREIGN KEY (credit_limit_id) REFERENCES credit_limits(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_limit_type
        CHECK (limit_type IN ('PURCHASE', 'CASH_ADVANCE', 'DAILY', 'MONTHLY')),
    CONSTRAINT chk_action
        CHECK (action IN ('ASSIGNED', 'INCREASED', 'DECREASED', 'UPDATED', 'CONSUMED', 'RELEASED')),
    CONSTRAINT chk_successful_has_values
        CHECK (successful = false OR (successful = true AND new_value_amount IS NOT NULL AND new_value_currency IS NOT NULL)),
    CONSTRAINT chk_failed_has_error
        CHECK (successful = true OR (successful = false AND error_message IS NOT NULL))
);

CREATE INDEX idx_history_credit_limit_id ON credit_limit_history(credit_limit_id, changed_at DESC);
CREATE INDEX idx_history_limit_type ON credit_limit_history(limit_type, changed_at DESC);
CREATE INDEX idx_history_action ON credit_limit_history(action, changed_at DESC);
CREATE INDEX idx_history_changed_by ON credit_limit_history(changed_by, changed_at DESC);
CREATE INDEX idx_history_changed_at ON credit_limit_history(changed_at DESC);
CREATE INDEX idx_history_successful ON credit_limit_history(successful, changed_at DESC);

CREATE INDEX idx_history_limit_type_action
    ON credit_limit_history(credit_limit_id, limit_type, action, changed_at DESC)
    WHERE successful = true;

CREATE UNIQUE INDEX idx_history_unique_change
    ON credit_limit_history(credit_limit_id, limit_type, action, changed_at, new_value_amount)
    WHERE successful = true;

COMMENT ON TABLE credit_limit_history IS 'Historial de cambios en límites de crédito';

-- ==========================================
-- CARD AUDIT
-- ==========================================
CREATE TABLE card_audit (
    id BIGSERIAL PRIMARY KEY,
    card_id VARCHAR(36) NOT NULL,
    entity_name VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT
);

CREATE INDEX idx_card_audit_card_id ON card_audit(card_id, changed_at DESC);
CREATE INDEX idx_card_audit_entity ON card_audit(entity_name, action, changed_at DESC);

COMMENT ON TABLE card_audit IS 'Auditoría completa de todas las operaciones';
