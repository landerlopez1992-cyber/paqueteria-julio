-- Agregar el estado 'ATRASADO' al tipo enum existente
ALTER TYPE estado_orden ADD VALUE IF NOT EXISTS 'ATRASADO';

-- Verificar los valores del enum
SELECT unnest(enum_range(NULL::estado_orden)) as estado;

