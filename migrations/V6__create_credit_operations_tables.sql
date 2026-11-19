-- =============================================
-- Migration: V6
-- Description: idempotent credit operations (card-limits) and their journal in payment-processing
-- =============================================

-- ==========================================
-- CREDIT OPERATIONS (card-limits)
-- ==========================================
-- card-limits registra todo movimiento de crédito (consumos, restauraciones y pagos del resumen),
-- idempotente por operation_id. Guarda lo que cada operación movió (deltas) para poder deshacerla
-- exactamente: positivo = consumió / acreditó, negativo = devolvió / usó.
-- Si el cliente no manda operation_id, card-limits genera uno con prefijo 'auto-' (no idempotente,
-- pero se puede cancelar).
-- VOIDED: se canceló antes de aplicarse; si la operación llega después, se rechaza.
CREATE TABLE credit_operations (
    operation_id        VARCHAR(64)     PRIMARY KEY,
    credit_limit_id     VARCHAR(36)     NOT NULL,
    operation_type      VARCHAR(30),
    status              VARCHAR(20)     NOT NULL,
    credit_delta        NUMERIC(15,2)   NOT NULL DEFAULT 0,
    daily_delta         NUMERIC(15,2)   NOT NULL DEFAULT 0,
    monthly_delta       NUMERIC(15,2)   NOT NULL DEFAULT 0,
    cash_advance_delta  NUMERIC(15,2)   NOT NULL DEFAULT 0,
    balance_delta       NUMERIC(15,2)   NOT NULL DEFAULT 0,
    currency            VARCHAR(3)      NOT NULL,
    applied_on          DATE            NOT NULL,
    description         VARCHAR(255),
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_at        TIMESTAMP,

    CONSTRAINT fk_credit_operations_credit_limit
        FOREIGN KEY (credit_limit_id) REFERENCES credit_limits (id),
    CONSTRAINT chk_credit_operations_status
        CHECK (status IN ('APPLIED', 'CANCELLED', 'VOIDED')),
    CONSTRAINT chk_credit_operations_type
        CHECK (operation_type IN ('CONSUME_PURCHASE', 'CONSUME_CASH_ADVANCE', 'RESTORE', 'RELEASE')
            OR (operation_type IS NULL AND status = 'VOIDED'))
);

CREATE INDEX idx_credit_operations_credit_limit ON credit_operations (credit_limit_id);

COMMENT ON TABLE credit_operations IS
    'Movimientos de crédito de card-limits (consumos, restauraciones y pagos): idempotencia por operation_id del cliente y cancelación. Sin id del cliente, operation_id = auto-<uuid>';
COMMENT ON COLUMN credit_operations.operation_id IS
    'Id del cliente (idempotente) o generado por card-limits con prefijo auto- (no idempotente)';
COMMENT ON COLUMN credit_operations.cash_advance_delta IS
    'Lo que movió la operación en credit_limits.cash_advance_consumed (positivo = consumió, negativo = devolvió)';
COMMENT ON COLUMN credit_operations.balance_delta IS
    'Lo que movió la operación en credit_limits.credit_balance (positivo = acreditó, negativo = usó)';

-- ==========================================
-- PAYMENT CREDIT OPERATIONS (payment-processing)
-- ==========================================
-- Registro de cada operación de crédito pedida a card-limits.
-- Se inserta PENDING antes de llamar y pasa a CONFIRMED en la misma transacción que guarda el pago.
-- Si esa transacción no confirma, la operación queda PENDING y se cancela en card-limits (COMPENSATED).
-- Sin FK a transactions: la transacción puede no haberse guardado nunca.
CREATE TABLE payment_credit_operations (
    operation_id        VARCHAR(64)     PRIMARY KEY,
    transaction_id      UUID            NOT NULL,
    card_id             VARCHAR(36)     NOT NULL,
    operation_type      VARCHAR(30)     NOT NULL,
    amount              NUMERIC(15,2)   NOT NULL,
    currency            VARCHAR(3)      NOT NULL,
    status              VARCHAR(20)     NOT NULL,
    attempts            INTEGER         NOT NULL DEFAULT 0,
    last_error          VARCHAR(1000),
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_payment_credit_operations_status
        CHECK (status IN ('PENDING', 'CONFIRMED', 'REJECTED', 'COMPENSATED')),
    CONSTRAINT chk_payment_credit_operations_type
        CHECK (operation_type IN ('CONSUME_PURCHASE', 'CONSUME_CASH_ADVANCE', 'RESTORE')),
    CONSTRAINT chk_payment_credit_operations_attempts CHECK (attempts >= 0)
);

CREATE INDEX idx_payment_credit_operations_pending ON payment_credit_operations (created_at)
    WHERE status = 'PENDING';
CREATE INDEX idx_payment_credit_operations_transaction ON payment_credit_operations (transaction_id);

COMMENT ON TABLE payment_credit_operations IS
    'Operaciones de crédito pedidas a card-limits por payment-processing (saga: confirmación o compensación)';
