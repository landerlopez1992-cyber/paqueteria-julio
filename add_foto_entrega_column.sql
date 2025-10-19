-- Agregar columna foto_entrega a la tabla ordenes

ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS foto_entrega TEXT;

COMMENT ON COLUMN ordenes.foto_entrega IS 'URL de la foto tomada por el repartidor al entregar la orden';

-- Verificar que la columna existe
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes' 
AND column_name = 'foto_entrega';

-- Mostrar algunas órdenes para verificar
SELECT 
    numero_orden,
    estado,
    foto_entrega,
    created_at
FROM ordenes 
ORDER BY created_at DESC 
LIMIT 5;
