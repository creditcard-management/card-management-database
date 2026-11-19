# 🌱 Seeds - Datos de Prueba (Development)

## Descripción

Scripts SQL para poblar la base de datos con datos de prueba realistas.

## Orden de Ejecución

**IMPORTANTE:** Ejecutar en este orden para respetar las Foreign Keys:
```
1. 001_test_cards.sql              (10 tarjetas + 5 auditorías)
2. 002_test_credit_limits.sql      (4 límites + 8 históricos)
3. 003_test_state_transitions.sql  (23 transiciones)
4. 004_test_exchange_rates.sql     (cotizaciones USD/ARS y EUR/ARS; requiere V9)
```

Los archivos 001 a 003 corren en una transacción con `ON_ERROR_STOP`: si una sentencia falla, no se carga nada de ese archivo y `make seed-dev` corta con error. **No son re-ejecutables** (las claves son fijas): para volver a cargarlos, correr antes `make clean-seeds`. El 004 sí se puede repetir (saltea los pares que ya tienen cotizaciones).

## Ejecutar Seeds

### Opción A: Con Make (Recomendado)
```bash
make seed-dev
```

### Opción B: Manualmente
```bash
# Ejecutar cada archivo
docker exec -i card-db-postgres psql -U postgres -d card_management_db < seeds/dev/001_test_cards.sql
docker exec -i card-db-postgres psql -U postgres -d card_management_db < seeds/dev/002_test_credit_limits.sql
docker exec -i card-db-postgres psql -U postgres -d card_management_db < seeds/dev/003_test_state_transitions.sql
docker exec -i card-db-postgres psql -U postgres -d card_management_db < seeds/dev/004_test_exchange_rates.sql
```

## Datos Creados

### Tarjetas (10)

| ID | Titular | Tipo | Categoría | Estado | Límite |
|----|---------|------|-----------|--------|--------|
| ...001 | Juan Pérez | VISA | GOLD | ACTIVE | $50,000 |
| ...002 | María González | MASTERCARD | PLATINUM | ACTIVE | $100,000 |
| ...003 | Carlos Rodríguez | VISA | CLASSIC | BLOCKED_FRAUD | $30,000 |
| ...004 | Ana Martínez | AMEX | BLACK | ISSUED | - |
| ...005 | Roberto Fernández | CABAL | GOLD | REQUESTED | - |
| ...006 | Laura Sánchez | NARANJA | PLATINUM | BLOCKED | - |
| ...007 | Diego López | VISA | INFINITE | CANCELLED | - |
| ...008 | Sofía Ramírez | VISA | CLASSIC | ACTIVE | $20,000 |
| ...009 | Martín Torres | MASTERCARD | GOLD | EXPIRED | - |
| ...010 | Lucía Morales | VISA | PLATINUM | APPROVED | - |

### Cotizaciones (2)

| Par | Tasa | Vigencia |
|-----|------|----------|
| USD/ARS | 1150.50 | Desde la carga, abierta |
| EUR/ARS | 1250.00 | Desde la carga, abierta |

Solo se insertan si el par no tiene cotizaciones (en ningún sentido). ARS → USD/EUR usa la cotización inversa.

### Datos sensibles de prueba

Las tarjetas 5 y 10 no tienen número (todavía no se emitieron). En la base, número y CVV están cifrados con la clave de desarrollo `k1` de card-data (el default de `ENCRYPTION_KEY_K1`) y el PIN como hash BCrypt. Si card-data corre con otra clave, no puede descifrarlos y responde 500 con esas tarjetas.

| ID | Titular | Número | CVV | PIN |
|----|---------|--------|-----|-----|
| ...001 | Juan Pérez | `4532123456789014` | `123` | `1357` |
| ...002 | María González | `5412345678901232` | `456` | `2468` |
| ...003 | Carlos Rodríguez | `4916123456789010` | `789` | `3579` |
| ...004 | Ana Martínez | `378282246310005` | `1234` | `4680` |
| ...006 | Laura Sánchez | `5896123456789011` | `567` | `6802` |
| ...007 | Diego López | `4539123456789017` | `890` | `7913` |
| ...008 | Sofía Ramírez | `4024123456789019` | `234` | `8024` |
| ...009 | Martín Torres | `5105123456789018` | `345` | `9135` |

### Escenarios de Prueba

1. **Ciclo completo (REQUESTED → ACTIVE):**
    - Tarjeta 1 (Juan Pérez)
    - Tarjeta 2 (María González)

2. **Bloqueo por fraude:**
    - Tarjeta 3 (Carlos Rodríguez)

3. **Pendiente de activación:**
    - Tarjeta 4 (Ana Martínez)

4. **Rechazada:**
    - Tarjeta 5 (Roberto Fernández)

5. **Bloqueada temporalmente:**
    - Tarjeta 6 (Laura Sánchez)

6. **Cancelada:**
    - Tarjeta 7 (Diego López)

7. **Transiciones fallidas:**
    - Intentos de activación sin límite
    - Intentos de desbloqueo no autorizados

## Limpiar Datos
```bash
# Eliminar solo datos de seeds (mantener schema)
docker exec -it card-db-postgres psql -U postgres -d card_management_db << EOF
DELETE FROM exchange_rates WHERE rate_id LIKE '770e8400-e29b-41d4-a716-%';
TRUNCATE TABLE state_transitions CASCADE;
TRUNCATE TABLE credit_limit_history CASCADE;
TRUNCATE TABLE credit_limits CASCADE;
TRUNCATE TABLE card_audit CASCADE;
TRUNCATE TABLE cards CASCADE;
EOF
```

## Notas

- ⚠️ **Solo para desarrollo** - NO usar en producción
- 🔒 PINs y CVVs son **ficticios** y están encriptados
- 📊 Datos realistas basados en casos de uso reales
- 🔗 Respeta todas las Foreign Keys y constraints
- 🧩 Los seeds siguen el schema actual (hasta V9). Si una migración cambia una tabla sembrada, hay que actualizar el seed: el `ON_ERROR_STOP` hace que el error se vea en vez de cargar datos a medias