-- Agregar columna es_urgente a la tabla ordenes

ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS es_urgente BOOLEAN DEFAULT FALSE;

-- Agregar comentario a la columna
COMMENT ON COLUMN ordenes.es_urgente IS 'Indica si la orden es urgente (requiere control de temperatura)';

-- Verificar que la columna se agregó correctamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'ordenes' AND column_name = 'es_urgente';
