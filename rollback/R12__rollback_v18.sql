-- =============================================
-- Rollback: V18
-- Date: 2026-11-14
-- Description: revert cumulative cash advances
-- =============================================
-- ⚠️ Requiere volver a una versión de card-limits sin adelantos acumulativos (con ddl-auto=validate, la
-- actual no arranca sin las columnas). Se pierde cuánto usó cada tarjeta en adelantos y lo que movió cada
-- operación en ellos: cancelar después una operación ya no devuelve ese uso.
-- Todo en una transacción: si algo falla, el esquema queda como estaba.

BEGIN;

ALTER TABLE credit_operations DROP COLUMN cash_advance_delta;
ALTER TABLE credit_limits DROP CONSTRAINT chk_cash_advance_consumed;
ALTER TABLE credit_limits DROP COLUMN cash_advance_consumed;

-- Quitar el registro de V18 del historial de Flyway
DELETE FROM flyway_schema_history WHERE version = '18';

COMMIT;
