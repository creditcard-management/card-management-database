-- =============================================
-- Migration: V7
-- Description: transactional outbox per service (card-data, payment-processing, card-limits)
-- =============================================

-- Cada servicio encola sus eventos de integración en la misma transacción que el cambio de negocio;
-- su relay los publica en Kafka después del commit. Las tres tablas tienen la misma estructura.
-- failed_at marca un error permanente: el evento no se reintenta y queda para revisión.

-- ==========================================
-- OUTBOX EVENTS (card-data)
-- ==========================================
CREATE TABLE outbox_events (
    id              BIGSERIAL       PRIMARY KEY,
    event_id        VARCHAR(36)     NOT NULL,
    aggregate_id    VARCHAR(36)     NOT NULL,
    topic           VARCHAR(100)    NOT NULL,
    event_type      VARCHAR(100)    NOT NULL,
    payload         TEXT            NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP,
    attempts        INTEGER         NOT NULL DEFAULT 0,
    last_error      VARCHAR(1000),
    failed_at       TIMESTAMP,

    CONSTRAINT uq_outbox_events_event_id UNIQUE (event_id),
    CONSTRAINT chk_outbox_attempts CHECK (attempts >= 0)
);

-- Pendientes en orden de inserción (lo que lee el relay)
CREATE INDEX idx_outbox_events_pending ON outbox_events (id)
    WHERE published_at IS NULL AND failed_at IS NULL;
CREATE INDEX idx_outbox_events_aggregate ON outbox_events (aggregate_id);
-- Limpieza de publicados por antigüedad y consulta de fallidos
CREATE INDEX idx_outbox_events_published_at ON outbox_events (published_at)
    WHERE published_at IS NOT NULL;
CREATE INDEX idx_outbox_events_failed ON outbox_events (id)
    WHERE failed_at IS NOT NULL;

COMMENT ON TABLE outbox_events IS 'Eventos pendientes de publicar en Kafka (transactional outbox)';
COMMENT ON COLUMN outbox_events.payload IS 'Evento serializado en JSON, se publica sin modificaciones';
COMMENT ON COLUMN outbox_events.failed_at IS
    'Error permanente: el evento no se reintenta. Para reintentarlo: UPDATE outbox_events SET failed_at = NULL WHERE id = ...';

-- ==========================================
-- PAYMENT OUTBOX EVENTS (payment-processing)
-- ==========================================
CREATE TABLE payment_outbox_events (
    id              BIGSERIAL       PRIMARY KEY,
    event_id        VARCHAR(36)     NOT NULL,
    aggregate_id    VARCHAR(36)     NOT NULL,
    topic           VARCHAR(100)    NOT NULL,
    event_type      VARCHAR(100)    NOT NULL,
    payload         TEXT            NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP,
    failed_at       TIMESTAMP,
    attempts        INTEGER         NOT NULL DEFAULT 0,
    last_error      VARCHAR(1000),

    CONSTRAINT uq_payment_outbox_events_event_id UNIQUE (event_id),
    CONSTRAINT chk_payment_outbox_attempts CHECK (attempts >= 0)
);

CREATE INDEX idx_payment_outbox_pending ON payment_outbox_events (id)
    WHERE published_at IS NULL AND failed_at IS NULL;
CREATE INDEX idx_payment_outbox_published_at ON payment_outbox_events (published_at)
    WHERE published_at IS NOT NULL;
CREATE INDEX idx_payment_outbox_failed ON payment_outbox_events (id)
    WHERE failed_at IS NOT NULL;

COMMENT ON TABLE payment_outbox_events IS
    'Eventos de payment-processing pendientes de publicar en Kafka (transactional outbox). Key = card_id';
COMMENT ON COLUMN payment_outbox_events.failed_at IS
    'Error permanente: no se reintenta. Para reintentarlo: UPDATE payment_outbox_events SET failed_at = NULL WHERE id = ...';

-- ==========================================
-- CREDIT LIMIT OUTBOX EVENTS (card-limits)
-- ==========================================
-- Cada cambio de un límite (asignación, cambio de límites, consumo, liberación) encola su evento.
CREATE TABLE credit_limit_outbox_events (
    id              BIGSERIAL       PRIMARY KEY,
    event_id        VARCHAR(36)     NOT NULL,
    aggregate_id    VARCHAR(36)     NOT NULL,
    topic           VARCHAR(100)    NOT NULL,
    event_type      VARCHAR(100)    NOT NULL,
    payload         TEXT            NOT NULL,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at    TIMESTAMP,
    failed_at       TIMESTAMP,
    attempts        INTEGER         NOT NULL DEFAULT 0,
    last_error      VARCHAR(1000),

    CONSTRAINT uq_credit_limit_outbox_events_event_id UNIQUE (event_id),
    CONSTRAINT chk_credit_limit_outbox_attempts CHECK (attempts >= 0)
);

CREATE INDEX idx_credit_limit_outbox_pending ON credit_limit_outbox_events (id)
    WHERE published_at IS NULL AND failed_at IS NULL;
CREATE INDEX idx_credit_limit_outbox_published_at ON credit_limit_outbox_events (published_at)
    WHERE published_at IS NOT NULL;
CREATE INDEX idx_credit_limit_outbox_failed ON credit_limit_outbox_events (id)
    WHERE failed_at IS NOT NULL;

COMMENT ON TABLE credit_limit_outbox_events IS
    'Eventos de card-limits pendientes de publicar en Kafka (transactional outbox). Key = card_id';
COMMENT ON COLUMN credit_limit_outbox_events.failed_at IS
    'Error permanente: no se reintenta. Para reintentarlo: UPDATE credit_limit_outbox_events SET failed_at = NULL WHERE id = ...';
