-- Script completo para arreglar la tabla ordenes con todas las columnas necesarias

-- 1. Agregar columna numero_orden si no existe
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS numero_orden TEXT;

-- 2. Agregar columna es_urgente si no existe
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS es_urgente BOOLEAN DEFAULT FALSE;

-- 3. Crear secuencia para numeración automática si no existe
CREATE SEQUENCE IF NOT EXISTS ordenes_numero_seq START 1000;

-- 4. Función para generar número de orden automático
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

-- 5. Trigger para asignar número de orden automáticamente
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

-- 6. Crear el trigger (eliminar el anterior si existe)
DROP TRIGGER IF EXISTS trigger_asignar_numero_orden ON ordenes;
CREATE TRIGGER trigger_asignar_numero_orden
    BEFORE INSERT ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION asignar_numero_orden();

-- 7. Actualizar órdenes existentes que no tengan número
UPDATE ordenes 
SET numero_orden = LPAD((ROW_NUMBER() OVER (ORDER BY created_at))::TEXT, 4, '0')
WHERE numero_orden IS NULL OR numero_orden = '';

-- 8. Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_ordenes_numero ON ordenes(numero_orden);

-- 9. Agregar comentarios a las columnas
COMMENT ON COLUMN ordenes.numero_orden IS 'Número de orden único con formato de 4 dígitos mínimo';
COMMENT ON COLUMN ordenes.es_urgente IS 'Indica si la orden es urgente (requiere control de temperatura)';

-- 10. Verificar que todo funciona
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'ordenes' 
AND column_name IN ('numero_orden', 'es_urgente')
ORDER BY column_name;

-- 11. Mostrar algunas órdenes de ejemplo
SELECT 
    numero_orden,
    emisor_nombre,
    destinatario_nombre,
    estado,
    es_urgente,
    created_at
FROM ordenes 
ORDER BY created_at DESC 
LIMIT 5;
