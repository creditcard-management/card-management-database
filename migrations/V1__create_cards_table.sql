-- =============================================
-- Migration: V1
-- Description: cards table (card-data / CardEntity)
-- =============================================

CREATE TABLE cards (
    -- Identificadores
    id VARCHAR(36) PRIMARY KEY,
    client_id VARCHAR(11) NOT NULL,
    -- Datos del titular
    holder_first_name VARCHAR(100) NOT NULL,
    holder_last_name VARCHAR(100) NOT NULL,
    holder_document_number VARCHAR(20) NOT NULL,
    holder_email VARCHAR(100) NOT NULL,
    holder_phone_number VARCHAR(20),
    holder_birth_date DATE NOT NULL,
    holder_address VARCHAR(500),
    -- Tipo y categoría
    type VARCHAR(20) NOT NULL,
    category VARCHAR(20) NOT NULL,
    -- Datos de la tarjeta (asignados al emitir)
    card_number_encrypted TEXT,
    last_four_digits VARCHAR(4),
    cvv_encrypted TEXT,
    pin_hash VARCHAR(100),
    -- Intentos fallidos de PIN consecutivos (card-data bloquea la tarjeta al llegar a 3)
    pin_failed_attempts INTEGER NOT NULL DEFAULT 0,
    expiration_month INTEGER,
    expiration_year INTEGER,
    -- Estado y razones
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    block_reason VARCHAR(500),
    cancelled_reason TEXT,
    -- Timestamps del ciclo de vida
    blocked_at TIMESTAMP,
    activated_at TIMESTAMP,
    issued_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    expired_at TIMESTAMP,
    -- Auditoría
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMP,
    -- Control de concurrencia optimista: cada UPDATE de card-data exige la versión que leyó y la
    -- incrementa. Si otra transacción cambió la tarjeta mientras tanto (por ejemplo, el job de
    -- vencimiento y un PUT /status a la vez), el guardado falla y la API responde 409.
    version BIGINT NOT NULL DEFAULT 0,

    CONSTRAINT chk_status
        CHECK (status IN ('REQUESTED', 'APPROVED', 'REJECTED', 'ISSUED', 'ACTIVE', 'BLOCKED', 'BLOCKED_FRAUD', 'CANCELLED', 'EXPIRED')),
    CONSTRAINT chk_type
        CHECK (type IN ('VISA', 'MASTERCARD', 'NARANJA', 'AMEX', 'CABAL')),
    CONSTRAINT chk_category
        CHECK (category IN ('CLASSIC', 'GOLD', 'PLATINUM', 'BLACK', 'INFINITE')),
    CONSTRAINT chk_pin_failed_attempts CHECK (pin_failed_attempts >= 0)
);

-- Índices
CREATE INDEX idx_cards_client_id ON cards(client_id) WHERE deleted = false;
CREATE INDEX idx_cards_status ON cards(status) WHERE deleted = false;
CREATE INDEX idx_cards_document ON cards(holder_document_number) WHERE deleted = false;
CREATE INDEX idx_cards_last_four ON cards(last_four_digits) WHERE deleted = false AND last_four_digits IS NOT NULL;
CREATE INDEX idx_cards_activated_at ON cards(activated_at) WHERE activated_at IS NOT NULL;

-- Comentarios
COMMENT ON TABLE cards IS 'Tabla principal de tarjetas';
COMMENT ON COLUMN cards.card_number_encrypted IS 'Número de tarjeta encriptado con AES-256';
COMMENT ON COLUMN cards.cvv_encrypted IS 'CVV encriptado con AES-256';
COMMENT ON COLUMN cards.pin_hash IS 'PIN hasheado con BCrypt';
COMMENT ON COLUMN cards.pin_failed_attempts IS 'Intentos fallidos de PIN consecutivos';
COMMENT ON COLUMN cards.version IS 'Versión para control de concurrencia optimista (JPA @Version)';
