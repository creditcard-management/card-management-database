-- =============================================
-- Seeds: Test Exchange Rates (Development)
-- Description: Cotizaciones iniciales para card-currency (V19 carga USD y EUR sin cotización)
-- =============================================
-- 1 base = rate quote. Cada par se cotiza en un solo sentido (X/ARS), como exige card-currency:
-- ARS → USD/EUR se resuelve con la cotización inversa.
-- Idempotente: solo inserta si el par no tiene cotizaciones en ningún sentido. Si ya hay, publicar por la API
-- (POST /api/v1/exchange-rates) para no pisar la vigencia de las existentes.

INSERT INTO exchange_rates (rate_id, base_currency, quote_currency, rate, valid_from, valid_to, source, created_at)
SELECT seed.rate_id, seed.base_currency, seed.quote_currency, seed.rate, NOW(), NULL, 'MANUAL', NOW()
FROM (VALUES
    ('770e8400-e29b-41d4-a716-446655440001', 'USD', 'ARS', 1150.50000000),
    ('770e8400-e29b-41d4-a716-446655440002', 'EUR', 'ARS', 1250.00000000)
) AS seed (rate_id, base_currency, quote_currency, rate)
WHERE NOT EXISTS (
    SELECT 1 FROM exchange_rates r
    WHERE (r.base_currency = seed.base_currency AND r.quote_currency = seed.quote_currency)
       OR (r.base_currency = seed.quote_currency AND r.quote_currency = seed.base_currency)
);
