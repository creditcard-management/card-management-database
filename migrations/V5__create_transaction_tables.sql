-- =============================================
-- Migration: V5
-- Description: payment-processing transactions, items and receipts
-- =============================================

-- ==========================================
-- TRANSACTIONS
-- ==========================================
CREATE TABLE transactions (
    transaction_id              UUID            NOT NULL,

    -- FK hacia cards(id) y merchants(id) → VARCHAR(36)
    card_id                     VARCHAR(36)     NOT NULL,
    merchant_id                 VARCHAR(36)     NOT NULL,

    -- Enums
    transaction_type            VARCHAR(50)     NOT NULL,
    transaction_status          VARCHAR(50)     NOT NULL,
    payment_method              VARCHAR(50)     NOT NULL,

    -- Amount Information
    amount                      NUMERIC(15, 2)  NOT NULL,
    currency                    VARCHAR(3)      NOT NULL,
    local_amount                NUMERIC(15, 2),
    local_currency              VARCHAR(3),
    -- Tasa de card-currency: hasta 11 enteros y 8 decimales (como exchange_rates.rate)
    exchange_rate               NUMERIC(19, 8),
    -- Cotización de card-currency usada (NULL si no hubo conversión).
    -- Sin FK: exchange_rates es de otro servicio y la transacción guarda la tasa aplicada igual.
    exchange_rate_id            VARCHAR(36),

    -- Card Information (PCI Compliant - Tokenized)
    card_number_token           VARCHAR(100)    NOT NULL,
    card_last_four              VARCHAR(4)      NOT NULL,
    card_holder_name            VARCHAR(100),
    expiration_date             VARCHAR(7),

    -- Authorization
    authorization_code          VARCHAR(50),
    authorization_date          TIMESTAMP,
    authorization_response_code VARCHAR(10),

    -- Merchant Information
    merchant_category_code      VARCHAR(4),
    merchant_name               VARCHAR(200),
    merchant_city               VARCHAR(100),
    merchant_country            VARCHAR(2),

    -- Transaction Details
    terminal_id                 VARCHAR(50),
    pos_entry_mode              VARCHAR(20),
    transaction_date            TIMESTAMP       NOT NULL,
    settlement_date             TIMESTAMP,

    -- Fraud & Risk
    risk_score                  INTEGER,
    fraud_check_status          VARCHAR(20),

    -- Status Information
    decline_reason              VARCHAR(500),
    reversal_reason             VARCHAR(500),

    -- Devoluciones: un REFUND apunta a la transacción que devuelve. payment-processing suma las
    -- devoluciones de una transacción para no devolver más que el original.
    original_transaction_id     UUID,

    -- Audit Fields
    created_at                  TIMESTAMP       NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMP       NOT NULL DEFAULT NOW(),
    created_by                  VARCHAR(100),
    version                     INTEGER         NOT NULL DEFAULT 0,

    CONSTRAINT pk_transactions PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transactions_card
        FOREIGN KEY (card_id)
            REFERENCES cards(id)
            ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_merchant
        FOREIGN KEY (merchant_id)
            REFERENCES merchants(id)
            ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_original
        FOREIGN KEY (original_transaction_id)
            REFERENCES transactions(transaction_id)
            ON DELETE RESTRICT,
    -- Solo las devoluciones tienen original
    CONSTRAINT chk_transactions_original_only_refunds
        CHECK (original_transaction_id IS NULL OR transaction_type = 'REFUND')
);

CREATE INDEX idx_transactions_card_id         ON transactions (card_id);
CREATE INDEX idx_transactions_merchant_id     ON transactions (merchant_id);
CREATE INDEX idx_transactions_status          ON transactions (transaction_status);
CREATE INDEX idx_transactions_date            ON transactions (transaction_date);
CREATE INDEX idx_transactions_settlement_date ON transactions (settlement_date);
CREATE INDEX idx_transactions_auth_code       ON transactions (authorization_code);
CREATE INDEX idx_transactions_original_transaction_id ON transactions (original_transaction_id)
    WHERE original_transaction_id IS NOT NULL;

COMMENT ON COLUMN transactions.exchange_rate IS 'Unidades de local_currency por unidad de currency';
COMMENT ON COLUMN transactions.exchange_rate_id IS 'exchange_rates.rate_id de card-currency usado para convertir';
COMMENT ON COLUMN transactions.original_transaction_id IS 'Transacción devuelta (solo para REFUND)';

-- ==========================================
-- TRANSACTION ITEMS
-- ==========================================
CREATE TABLE transaction_items (
    item_id          UUID            NOT NULL,
    transaction_id   UUID            NOT NULL,
    item_description VARCHAR(500),
    quantity         INTEGER         NOT NULL DEFAULT 1,
    unit_price       NUMERIC(15, 2)  NOT NULL,
    total_amount     NUMERIC(15, 2)  NOT NULL,
    created_at       TIMESTAMP       NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_transaction_items PRIMARY KEY (item_id),
    CONSTRAINT fk_transaction_items_transaction
        FOREIGN KEY (transaction_id)
            REFERENCES transactions(transaction_id)
            ON DELETE CASCADE
);

CREATE INDEX idx_transaction_items_transaction_id ON transaction_items (transaction_id);

-- ==========================================
-- TRANSACTION RECEIPTS
-- ==========================================
CREATE TABLE transaction_receipts (
    receipt_id      UUID            NOT NULL,
    transaction_id  UUID            NOT NULL,
    receipt_number  VARCHAR(50)     NOT NULL,
    receipt_type    VARCHAR(20)     NOT NULL,
    receipt_data    JSONB           NOT NULL,
    generated_at    TIMESTAMP       NOT NULL DEFAULT NOW(),
    delivered_at    TIMESTAMP,
    delivery_status VARCHAR(20),

    CONSTRAINT pk_transaction_receipts      PRIMARY KEY (receipt_id),
    CONSTRAINT uq_receipts_transaction_id   UNIQUE (transaction_id),
    CONSTRAINT uq_receipts_receipt_number   UNIQUE (receipt_number),
    CONSTRAINT fk_receipts_transaction
        FOREIGN KEY (transaction_id)
            REFERENCES transactions(transaction_id)
            ON DELETE CASCADE
);

CREATE INDEX idx_receipts_transaction_id ON transaction_receipts (transaction_id);
CREATE UNIQUE INDEX idx_receipts_receipt_number ON transaction_receipts (receipt_number);
