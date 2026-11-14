-- =============================================
-- Rollback: V17
-- Date: 2026-11-14
-- Description: revert RELEASE in credit_operations
-- =============================================
-- ⚠️ Requiere volver a una versión de card-limits que no registra liberaciones.
-- El CHECK anterior no admite RELEASE: si hay liberaciones registradas, el ALTER falla. Revisar antes:
--   SELECT count(*) FROM credit_operations WHERE operation_type = 'RELEASE';
-- Para descartarlas (se pierde el registro de esos pagos y ya no se pueden cancelar):
--   DELETE FROM credit_operations WHERE operation_type = 'RELEASE';
-- Todo en una transacción: si falla, el CHECK de V17 queda como estaba (no se deja la tabla sin CHECK).

BEGIN;

ALTER TABLE credit_operations DROP CONSTRAINT chk_credit_operations_type;
ALTER TABLE credit_operations ADD CONSTRAINT chk_credit_operations_type
    CHECK (operation_type IN ('CONSUME_PURCHASE', 'CONSUME_CASH_ADVANCE', 'RESTORE')
        OR (operation_type IS NULL AND status = 'VOIDED'));

COMMENT ON TABLE credit_operations IS
    'Operaciones de crédito de card-limits identificadas por el cliente (idempotencia y cancelación)';
COMMENT ON COLUMN credit_operations.operation_id IS NULL;

-- Quitar el registro de V17 del historial de Flyway
DELETE FROM flyway_schema_history WHERE version = '17';

COMMIT;
