-- =============================================
-- Migration: V20
-- Date: 2026-11-15
-- Description: transactions keep the card-currency rate used to bill a foreign-currency payment
-- =============================================

-- payment-processing convierte a la moneda del límite con card-currency: las tasas tienen 8 decimales y
-- hasta 11 enteros (como exchange_rates.rate). Con NUMERIC(10,6) una tasa >= 10000 no entraba y las tasas
-- chicas (ARS→USD ≈ 0,00083333) perdían precisión. Ensanchar no pierde datos.
ALTER TABLE transactions ALTER COLUMN exchange_rate TYPE NUMERIC(19, 8);

-- Cotización de card-currency usada (nula si no hubo conversión o en transacciones anteriores).
-- Sin FK: exchange_rates es de otro servicio y la transacción guarda la tasa aplicada igual.
ALTER TABLE transactions ADD COLUMN exchange_rate_id VARCHAR(36);

COMMENT ON COLUMN transactions.exchange_rate IS 'Unidades de local_currency por unidad de currency';
COMMENT ON COLUMN transactions.exchange_rate_id IS 'exchange_rates.rate_id de card-currency usado para convertir';
