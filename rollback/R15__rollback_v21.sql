-- =============================================
-- Rollback: V21
-- Date: 2026-11-18
-- Description: revert credit balance (saldo a favor)
-- =============================================
-- ⚠️ Requiere volver a una versión de card-limits sin saldo a favor (con ddl-auto=validate, la actual no
-- arranca sin las columnas). Se pierde el saldo a favor de cada tarjeta: ANTES de ejecutarlo, revisar
--     SELECT id, card_id, credit_balance FROM credit_limits WHERE credit_balance > 0;
-- y resolver esos saldos (devolución al cliente o ajuste manual). El disponible guardado de esas tarjetas
-- incluye el saldo, así que se recalcula como límite − consumido.
-- Todo en una transacción: si algo falla, el esquema queda como estaba.

BEGIN;

UPDATE credit_limits
SET available_credit_amount = purchase_limit_amount - consumed_credit_amount
WHERE credit_balance > 0;

ALTER TABLE credit_operations DROP COLUMN balance_delta;
ALTER TABLE credit_limits DROP CONSTRAINT chk_credit_balance;
ALTER TABLE credit_limits DROP COLUMN credit_balance;

-- Quitar el registro de V21 del historial de Flyway
DELETE FROM flyway_schema_history WHERE version = '21';

COMMIT;
