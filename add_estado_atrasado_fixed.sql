-- Paso 1: Agregar el estado 'ATRASADO' al tipo enum existente
ALTER TYPE estado_orden ADD VALUE IF NOT EXISTS 'ATRASADO';

-- Paso 2: Verificar los valores del enum (ejecutar en una consulta separada)
SELECT unnest(enum_range(NULL::estado_orden)) as estado;
