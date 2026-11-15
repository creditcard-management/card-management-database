-- =============================================
-- Seeds: Test Cards (Development)
-- Description: Datos de prueba para cards y card_audit
-- =============================================

-- Todo o nada: si una sentencia falla, psql corta (y make seed-dev también) y no queda nada de este archivo.
-- No es re-ejecutable: para volver a cargar, correr antes make clean-seeds.
\set ON_ERROR_STOP on
BEGIN;

-- Números de tarjeta y CVV: cifrados con AES-256-GCM y la clave de desarrollo k1 de card-data (el default de
-- ENCRYPTION_KEY_K1 en application.yml y docker-compose). Con otra clave, card-data no los puede descifrar (500).
-- PIN: hash BCrypt (strength 12). Los números (válidos por Luhn), CVV y PIN en claro están en README.md.

-- =============================================
-- CARDS - Datos de Prueba
-- =============================================

-- Tarjeta 1: ACTIVE - Visa Gold
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440001',
    '20123456789',
    'Juan', 'Pérez', '20123456789',
    'juan.perez@email.com', '+54 11 1234-5678', '1990-05-15', 'Av. Corrientes 1234, CABA',
    'VISA', 'GOLD',
    'k1:+QV8QXE6O9d36YAJO4Z9BPTGQm0PNPWNjwtedLWExvw2/hf8glGXw0gweoE=', '9014', 'k1:sufEnXEDbev0aT4wJRT4MRed/QaxHZ2vP/9bcHlZog==', '$2a$12$V9ftq4eQHc8jH.HVRUcN7OfkPLj2PS6hGIC9IogALqs7v/9gEEyF6',
    12, 2028,
    'ACTIVE', NOW() - INTERVAL '6 months', NOW()
);

-- Tarjeta 2: ACTIVE - Mastercard Platinum
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440002',
    '27987654321',
    'María', 'González', '27987654321',
    'maria.gonzalez@email.com', '+54 11 8765-4321', '1985-08-22', 'Av. Santa Fe 5678, CABA',
    'MASTERCARD', 'PLATINUM',
    'k1:4v05rJ0FNP5rrjVPr+cK/2J9MQtj7EomBRXT49nTjzQScZZTRsBc+DSIU0Q=', '1232', 'k1:qb3Xjn/0ipjGaDjfxfY0sUYGSRt3Z3ov47bKChzo0w==', '$2a$12$fwzXdcDM3aEPrU8E7H7Uq.Pf/pi1NnOQjgNcZrsXvEVt3.Ot4M4nq',
    6, 2027,
    'ACTIVE', NOW() - INTERVAL '1 year', NOW()
);

-- Tarjeta 3: BLOCKED - Visa Classic (Bloqueada por fraude)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, block_reason, blocked_at, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440003',
    '23456789012',
    'Carlos', 'Rodríguez', '23456789012',
    'carlos.rodriguez@email.com', '+54 11 2345-6789', '1992-03-10', 'Av. Rivadavia 9012, CABA',
    'VISA', 'CLASSIC',
    'k1:Cz8Jk4RNL9h4+ogRd/GyunmNgA+QQNfK9ZU7J5KLvRIYH1IIA2oSP+Y5Rq4=', '9010', 'k1:Hor+xp737r/4EUDw0fZ6oeNFP3GfwjwoRIv71y39PA==', '$2a$12$w3QJmJEv54GOYqYHiAqDkukJtKb6Vp/o.H7TSLUsyfgv5gOqrVLUK',
    3, 2028,
    'BLOCKED_FRAUD', 'Transacciones sospechosas detectadas', NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '3 months', NOW() - INTERVAL '15 days'
);

-- Tarjeta 4: ISSUED - Amex Black (Emitida pero no activada)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440004',
    '20111222333',
    'Ana', 'Martínez', '20111222333',
    'ana.martinez@email.com', '+54 11 1112-2233', '1988-11-30', 'Av. Libertador 3456, CABA',
    'AMEX', 'BLACK',
    'k1:SqlPLAYUlaIP9IA48UUL0p5dUz8RVBTzIrkq4QwV9BOFesT1kxUlltANXQ==', '0005', 'k1:0T/gmRoUruGM+jrDbFsz0P/Y/qYvwBpFr0rF4qsz/fE=', '$2a$12$qmbADPKjmrB5mWAHC.6ez.ZQvUs.rNJDqqkvmrQz88/H2GfdjI1OO',
    9, 2029,
    'ISSUED', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'
);

-- Tarjeta 5: REQUESTED - Cabal Gold (Solicitada, pendiente aprobación)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440005',
    '24567890123',
    'Roberto', 'Fernández', '24567890123',
    'roberto.fernandez@email.com', '+54 11 4567-8901', '1995-07-18', 'Av. Cabildo 7890, CABA',
    'CABAL', 'GOLD',
    'REQUESTED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'
);

-- Tarjeta 6: BLOCKED - Naranja Platinum (Bloqueada temporalmente)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, block_reason, blocked_at, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440006',
    '26789012345',
    'Laura', 'Sánchez', '26789012345',
    'laura.sanchez@email.com', '+54 11 6789-0123', '1991-12-05', 'Av. Callao 2345, CABA',
    'NARANJA', 'PLATINUM',
    'k1:0IP8GNNJocOoxbulE6qd9Y+uucAaLGuGf5FijU8LIY23EPybXYUfGqIsXeg=', '9011', 'k1:+wyQy6Yw1LnCn9RX12Voy1zZ6wWRYHq8zbJoR5UYHg==', '$2a$12$mgCyhnUD1sTPI0gh3Miy5eSjfqkGelxN0Yyc0uiDLg8fXo84.ucze',
    11, 2027,
    'BLOCKED', 'Bloqueo temporal por pérdida de tarjeta', NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '8 months', NOW() - INTERVAL '5 days'
);

-- Tarjeta 7: CANCELLED - Visa Infinite (Cancelada por cliente)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, created_at, updated_at, deleted, deleted_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440007',
    '25678901234',
    'Diego', 'López', '25678901234',
    'diego.lopez@email.com', '+54 11 5678-9012', '1987-04-25', 'Av. Las Heras 4567, CABA',
    'VISA', 'INFINITE',
    'k1:YT5A8APLzlNqk/l9t2SMYdkxVE1pAdR7k0qom9xkuC98vVNSNXunaA6C4PU=', '9017', 'k1:abEkWn5j9Qd82yHKcC9DQcJfiJG5hVs9Myn6Oq2dDQ==', '$2a$12$sr70eC.uwViaYaYwgan.HuT678NXmFE0CwPj71aHDc17HZHQKwMVW',
    5, 2026,
    'CANCELLED', NOW() - INTERVAL '2 years', NOW() - INTERVAL '1 month', TRUE, NOW() - INTERVAL '1 month'
);

-- Tarjeta 8: ACTIVE - Visa Classic (Cliente joven)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440008',
    '28901234567',
    'Sofía', 'Ramírez', '28901234567',
    'sofia.ramirez@email.com', '+54 11 8901-2345', '2000-09-14', 'Av. Belgrano 6789, CABA',
    'VISA', 'CLASSIC',
    'k1:XBWD0XPkAH+CrH+3teEwPVDzc4Yyz9HKwsoNi2Vf9XEyuxGkfL/xxiRbfOc=', '9019', 'k1:AJpVLhBCbNDLlsRz+nVqswRau7yEn0tZZ4PqkzqPXg==', '$2a$12$ptKbhLWPmrYGyKhzQedKouuEQDbXQ7GSBqixd7vnOEX5qkGab5Kqy',
    8, 2029,
    'ACTIVE', NOW() - INTERVAL '4 months', NOW()
);

-- Tarjeta 9: EXPIRED - Mastercard Gold (Vencida)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    card_number_encrypted, last_four_digits, cvv_encrypted, pin_hash,
    expiration_month, expiration_year,
    status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440009',
    '22345678901',
    'Martín', 'Torres', '22345678901',
    'martin.torres@email.com', '+54 11 2345-6789', '1983-06-20', 'Av. 9 de Julio 1234, CABA',
    'MASTERCARD', 'GOLD',
    'k1:pThe36ovTDs+5WF8MYryaSnVM0kXBs7s1vFbCJQx5fHngblSZGzk3bKj8UQ=', '9018', 'k1:ncSJfB/HTpRIknE6gjct9ZkBmmp9tMIIvAAht/Nw8g==', '$2a$12$wam1id8ysaSh6gC1ctqhue6fycrML2N13uyUElIfEQjuanMv7bAQW',
    1, 2025,
    'EXPIRED', NOW() - INTERVAL '5 years', NOW() - INTERVAL '11 months'
);

-- Tarjeta 10: APPROVED - Visa Platinum (Aprobada, pendiente emisión)
INSERT INTO cards (
    id, client_id,
    holder_first_name, holder_last_name, holder_document_number,
    holder_email, holder_phone_number, holder_birth_date, holder_address,
    type, category,
    status, created_at, updated_at
) VALUES (
    '550e8400-e29b-41d4-a716-446655440010',
    '29012345678',
    'Lucía', 'Morales', '29012345678',
    'lucia.morales@email.com', '+54 11 9012-3456', '1993-02-28', 'Av. Córdoba 8901, CABA',
    'VISA', 'PLATINUM',
    'APPROVED', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'
);

-- =============================================
-- CARD_AUDIT - Auditoría de Cambios
-- =============================================

-- Formato de V3: entity_name + action y los valores cambiados como JSONB (old_values / new_values).
-- El motivo del cambio va en new_values.reason (la tabla no tiene columna propia).

-- Auditoría: Cambio de email en tarjeta 1
INSERT INTO card_audit (card_id, entity_name, action, old_values, new_values, changed_by, changed_at)
VALUES (
    '550e8400-e29b-41d4-a716-446655440001', 'Card', 'UPDATE',
    '{"holder_email": "juan.perez.old@email.com"}',
    '{"holder_email": "juan.perez@email.com", "reason": "Actualización de contacto solicitada por cliente"}',
    'admin@bank.com', NOW() - INTERVAL '30 days'
);

-- Auditoría: Cambio de teléfono en tarjeta 2
INSERT INTO card_audit (card_id, entity_name, action, old_values, new_values, changed_by, changed_at)
VALUES (
    '550e8400-e29b-41d4-a716-446655440002', 'Card', 'UPDATE',
    '{"holder_phone_number": "+54 11 0000-0000"}',
    '{"holder_phone_number": "+54 11 8765-4321", "reason": "Verificación y actualización de datos de contacto"}',
    'system@bank.com', NOW() - INTERVAL '60 days'
);

-- Auditoría: Cambio de estado en tarjeta 3 (ACTIVE → BLOCKED_FRAUD)
INSERT INTO card_audit (card_id, entity_name, action, old_values, new_values, changed_by, changed_at)
VALUES (
    '550e8400-e29b-41d4-a716-446655440003', 'Card', 'STATUS_CHANGE',
    '{"status": "ACTIVE"}',
    '{"status": "BLOCKED_FRAUD", "reason": "Sistema de detección de fraude detectó actividad sospechosa"}',
    'fraud-detection@bank.com', NOW() - INTERVAL '15 days'
);

-- Auditoría: Cambio de dirección en tarjeta 2
INSERT INTO card_audit (card_id, entity_name, action, old_values, new_values, changed_by, changed_at)
VALUES (
    '550e8400-e29b-41d4-a716-446655440002', 'Card', 'UPDATE',
    '{"holder_address": "Av. Santa Fe 1000, CABA"}',
    '{"holder_address": "Av. Santa Fe 5678, CABA", "reason": "Mudanza notificada por el cliente"}',
    'maria.gonzalez@email.com', NOW() - INTERVAL '45 days'
);

-- Auditoría: Reset de PIN en tarjeta 1 (sin los hashes: la auditoría no guarda secretos)
INSERT INTO card_audit (card_id, entity_name, action, old_values, new_values, changed_by, changed_at)
VALUES (
    '550e8400-e29b-41d4-a716-446655440001', 'Card', 'PIN_RESET',
    NULL,
    '{"pin_reset": true, "reason": "Reseteo de PIN solicitado por cliente desde app móvil"}',
    'juan.perez@email.com', NOW() - INTERVAL '10 days'
);

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Seeds aplicadas exitosamente!';
    RAISE NOTICE '   - 10 tarjetas creadas';
    RAISE NOTICE '   - 5 registros de auditoría creados';
    RAISE NOTICE '';
    RAISE NOTICE 'Estados de tarjetas:';
    RAISE NOTICE '   - ACTIVE: 3 tarjetas';
    RAISE NOTICE '   - BLOCKED: 1 tarjeta';
    RAISE NOTICE '   - BLOCKED_FRAUD: 1 tarjeta';
    RAISE NOTICE '   - ISSUED: 1 tarjeta';
    RAISE NOTICE '   - REQUESTED: 1 tarjeta';
    RAISE NOTICE '   - APPROVED: 1 tarjeta';
    RAISE NOTICE '   - CANCELLED: 1 tarjeta';
    RAISE NOTICE '   - EXPIRED: 1 tarjeta';
END $$;

COMMIT;
