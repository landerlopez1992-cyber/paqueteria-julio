-- Agregar columna notas a la tabla ordenes

ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS notas TEXT;

COMMENT ON COLUMN ordenes.notas IS 'Notas adicionales para la orden (ej: dejar en la puerta)';

-- Verificar que la columna existe
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes' 
AND column_name = 'notas';

