-- =============================================
-- Migration: V21
-- Date: 2026-11-18
-- Description: credit balance (saldo a favor) in card-limits
-- =============================================

-- card-limits acredita como saldo a favor lo que se paga o se devuelve de más: un pago del resumen mayor a lo
-- consumido, o la devolución de una compra que ya se pagó. El saldo se suma al disponible y lo usan primero los
-- consumos siguientes, así que nunca convive con deuda: si uno es mayor a cero, el otro es cero.
-- Las tarjetas existentes arrancan en 0: lo que antes no se acreditó (solo se logueaba) no se reconstruye.
-- Desplegar ANTES que la versión de card-limits que usa estas columnas (con ddl-auto=validate no arranca sin ellas).
ALTER TABLE credit_limits ADD COLUMN credit_balance NUMERIC(15,2) NOT NULL DEFAULT 0;
ALTER TABLE credit_limits ADD CONSTRAINT chk_credit_balance
    CHECK (credit_balance >= 0 AND (credit_balance = 0 OR consumed_credit_amount = 0));

COMMENT ON COLUMN credit_limits.credit_balance IS
    'Saldo a favor (en la moneda del límite de compras). Mayor a cero solo si consumed_credit_amount es cero';

-- Lo que movió cada operación en el saldo a favor, para poder deshacerla exactamente
-- (positivo = lo acreditó: pago o devolución de más; negativo = lo usó: un consumo).
ALTER TABLE credit_operations ADD COLUMN balance_delta NUMERIC(15,2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN credit_operations.balance_delta IS
    'Lo que movió la operación en credit_limits.credit_balance (positivo = acreditó, negativo = usó)';
