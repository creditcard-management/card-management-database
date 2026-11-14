-- =============================================
-- Migration: V17
-- Date: 2026-11-14
-- Description: card-limits records payments (release-credit) in credit_operations
-- =============================================

-- card-limits registra todo movimiento de crédito en credit_operations, también las liberaciones
-- (pago del resumen, tipo RELEASE). Si el cliente no manda operation_id, card-limits genera uno
-- con prefijo 'auto-' (no idempotente, pero se puede cancelar).
-- Desplegar ANTES que la versión de card-limits que registra RELEASE: con el CHECK anterior,
-- cada release-credit falla.
ALTER TABLE credit_operations DROP CONSTRAINT chk_credit_operations_type;
ALTER TABLE credit_operations ADD CONSTRAINT chk_credit_operations_type
    CHECK (operation_type IN ('CONSUME_PURCHASE', 'CONSUME_CASH_ADVANCE', 'RESTORE', 'RELEASE')
        OR (operation_type IS NULL AND status = 'VOIDED'));

COMMENT ON TABLE credit_operations IS
    'Movimientos de crédito de card-limits (consumos, restauraciones y pagos): idempotencia por operation_id del cliente y cancelación. Sin id del cliente, operation_id = auto-<uuid>';
COMMENT ON COLUMN credit_operations.operation_id IS
    'Id del cliente (idempotente) o generado por card-limits con prefijo auto- (no idempotente)';
