-- Script simple para agregar las columnas faltantes

-- 1. Agregar columna numero_orden si no existe
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS numero_orden TEXT;

-- 2. Agregar columna es_urgente si no existe
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS es_urgente BOOLEAN DEFAULT FALSE;

-- 3. Actualizar órdenes existentes que no tengan número
UPDATE ordenes 
SET numero_orden = LPAD((ROW_NUMBER() OVER (ORDER BY created_at))::TEXT, 4, '0')
WHERE numero_orden IS NULL OR numero_orden = '';

-- 4. Eliminar función y trigger anteriores si existen
DROP TRIGGER IF EXISTS trigger_asignar_numero_orden ON ordenes;
DROP TRIGGER IF EXISTS set_numero_orden ON ordenes;
DROP FUNCTION IF EXISTS asignar_numero_orden();
DROP FUNCTION IF EXISTS generar_numero_orden();

-- 5. Eliminar secuencia anterior si existe
DROP SEQUENCE IF EXISTS ordenes_numero_seq;

-- 6. Crear nueva secuencia
CREATE SEQUENCE ordenes_numero_seq START 1000;

-- 7. Crear nueva función que retorna VOID
CREATE OR REPLACE FUNCTION set_numero_orden()
RETURNS TRIGGER AS $$
DECLARE
    siguiente_numero INTEGER;
BEGIN
    -- Solo asignar número si no se proporciona uno
    IF NEW.numero_orden IS NULL OR NEW.numero_orden = '' THEN
        siguiente_numero := nextval('ordenes_numero_seq');
        NEW.numero_orden := LPAD(siguiente_numero::TEXT, 4, '0');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Crear el trigger
CREATE TRIGGER trigger_set_numero_orden
    BEFORE INSERT ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION set_numero_orden();

-- 9. Verificar columnas
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes' 
AND column_name IN ('numero_orden', 'es_urgente')
ORDER BY column_name;


