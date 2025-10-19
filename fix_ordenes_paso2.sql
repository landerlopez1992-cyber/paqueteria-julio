-- PASO 2: Actualizar órdenes existentes con números secuenciales

-- Actualizar órdenes existentes usando un CTE
WITH numeradas AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (ORDER BY created_at) as num
    FROM ordenes
    WHERE numero_orden IS NULL OR numero_orden = ''
)
UPDATE ordenes
SET numero_orden = LPAD(numeradas.num::TEXT, 4, '0')
FROM numeradas
WHERE ordenes.id = numeradas.id;

-- Verificar órdenes actualizadas
SELECT 
    numero_orden,
    emisor_nombre,
    destinatario_nombre,
    estado,
    created_at
FROM ordenes 
ORDER BY created_at DESC 
LIMIT 10;
