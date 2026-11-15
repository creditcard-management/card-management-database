-- =============================================
-- Rollback: V20
-- Date: 2026-11-15
-- Description: drop transactions.exchange_rate_id and narrow exchange_rate back to NUMERIC(10,6)
-- =============================================
-- ⚠️ Falla si hay tasas >= 10000 y redondea a 6 decimales. Revisar antes de ejecutar:
--   SELECT count(*) FROM transactions WHERE exchange_rate >= 10000;

ALTER TABLE transactions DROP COLUMN IF EXISTS exchange_rate_id;
ALTER TABLE transactions ALTER COLUMN exchange_rate TYPE NUMERIC(10, 6);
