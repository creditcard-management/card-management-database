-- =============================================
-- Migration: V18
-- Date: 2026-11-14
-- Description: cumulative cash advances in card-limits
-- =============================================

-- card-limits lleva cuánto se usó en adelantos: cada adelanto descuenta del tope de adelantos hasta que un
-- pago lo baje (los pagos cancelan primero los adelantos). Es parte de lo consumido, nunca mayor.
-- Las tarjetas existentes arrancan en 0: no se reconstruye el uso histórico de adelantos.
-- Desplegar ANTES que la versión de card-limits que usa estas columnas (con ddl-auto=validate no arranca sin ellas).
ALTER TABLE credit_limits ADD COLUMN cash_advance_consumed NUMERIC(15,2) NOT NULL DEFAULT 0;
ALTER TABLE credit_limits ADD CONSTRAINT chk_cash_advance_consumed
    CHECK (cash_advance_consumed >= 0 AND cash_advance_consumed <= consumed_credit_amount);

COMMENT ON COLUMN credit_limits.cash_advance_consumed IS
    'Parte de consumed_credit_amount usada en adelantos (en la moneda del límite de adelantos)';

-- Lo que movió cada operación en el uso de adelantos, para poder deshacerla exactamente
-- (positivo = consumió adelanto, negativo = lo devolvió: reverso de un adelanto o pago).
ALTER TABLE credit_operations ADD COLUMN cash_advance_delta NUMERIC(15,2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN credit_operations.cash_advance_delta IS
    'Lo que movió la operación en credit_limits.cash_advance_consumed (positivo = consumió, negativo = devolvió)';
