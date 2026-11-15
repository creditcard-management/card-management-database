-- =============================================
-- Rollback: V19
-- Date: 2026-11-15
-- Description: drop currency catalog and exchange rates
-- =============================================
-- ⚠️ Se pierden las monedas dadas de alta y todo el historial de cotizaciones.

DROP TABLE IF EXISTS exchange_rates;
DROP TABLE IF EXISTS currencies;
