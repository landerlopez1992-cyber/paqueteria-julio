-- Script para agregar numeración automática de órdenes y mejorar la lógica de repartidores

-- 1. Agregar columna para número de orden
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS numero_orden TEXT;

-- 2. Crear secuencia para numeración automática
CREATE SEQUENCE IF NOT EXISTS ordenes_numero_seq START 1000;

-- 3. Función para generar número de orden automático
CREATE OR REPLACE FUNCTION generar_numero_orden()
RETURNS TEXT AS $$
DECLARE
    siguiente_numero INTEGER;
    numero_formateado TEXT;
BEGIN
    -- Obtener el siguiente número de la secuencia
    siguiente_numero := nextval('ordenes_numero_seq');
    
    -- Formatear con mínimo 4 dígitos (rellenar con ceros a la izquierda)
    numero_formateado := LPAD(siguiente_numero::TEXT, 4, '0');
    
    RETURN numero_formateado;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger para asignar número de orden automáticamente
CREATE OR REPLACE FUNCTION asignar_numero_orden()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo asignar número si no se proporciona uno
    IF NEW.numero_orden IS NULL OR NEW.numero_orden = '' THEN
        NEW.numero_orden := generar_numero_orden();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Crear el trigger
DROP TRIGGER IF EXISTS trigger_asignar_numero_orden ON ordenes;
CREATE TRIGGER trigger_asignar_numero_orden
    BEFORE INSERT ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION asignar_numero_orden();

-- 6. Función para buscar repartidores por provincia
CREATE OR REPLACE FUNCTION buscar_repartidores_por_provincia(provincia_destino TEXT)
RETURNS TABLE(
    id UUID,
    nombre TEXT,
    email TEXT,
    telefono TEXT,
    tipo_vehiculo TEXT,
    provincias_asignadas TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.nombre,
        u.email,
        u.telefono,
        u.tipo_vehiculo,
        u.provincias_asignadas
    FROM usuarios u
    WHERE u.rol = 'REPARTIDOR'
    AND (
        u.provincias_asignadas IS NULL 
        OR provincia_destino = ANY(u.provincias_asignadas)
    )
    ORDER BY u.nombre;
END;
$$ LANGUAGE plpgsql;

-- 7. Función para asignar repartidor automáticamente
CREATE OR REPLACE FUNCTION asignar_repartidor_automatico(provincia_destino TEXT)
RETURNS TEXT AS $$
DECLARE
    repartidor_disponible RECORD;
    repartidor_nombre TEXT;
BEGIN
    -- Buscar el primer repartidor disponible para la provincia
    SELECT nombre INTO repartidor_nombre
    FROM buscar_repartidores_por_provincia(provincia_destino)
    LIMIT 1;
    
    -- Si no hay repartidor específico para la provincia, buscar cualquier repartidor
    IF repartidor_nombre IS NULL THEN
        SELECT nombre INTO repartidor_nombre
        FROM usuarios
        WHERE rol = 'REPARTIDOR'
        LIMIT 1;
    END IF;
    
    RETURN repartidor_nombre;
END;
$$ LANGUAGE plpgsql;

-- 8. Actualizar órdenes existentes que no tengan número
UPDATE ordenes 
SET numero_orden = LPAD((ROW_NUMBER() OVER (ORDER BY created_at))::TEXT, 4, '0')
WHERE numero_orden IS NULL OR numero_orden = '';

-- 9. Crear índice para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_ordenes_numero ON ordenes(numero_orden);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol_provincias ON usuarios(rol, provincias_asignadas);

-- 10. Verificar que todo funciona
SELECT 
    'Órdenes con números asignados:' as descripcion,
    COUNT(*) as cantidad
FROM ordenes 
WHERE numero_orden IS NOT NULL AND numero_orden != '';

-- 11. Mostrar algunos ejemplos
SELECT 
    numero_orden,
    emisor_nombre,
    destinatario_nombre,
    estado,
    created_at
FROM ordenes 
ORDER BY created_at DESC 
LIMIT 5;
