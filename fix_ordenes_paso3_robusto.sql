-- PASO 3: Crear secuencia, función y trigger para nuevas órdenes (VERSIÓN ROBUSTA)

-- 1. Eliminar trigger y función anteriores si existen
DROP TRIGGER IF EXISTS trigger_set_numero_orden ON ordenes;
DROP TRIGGER IF EXISTS set_numero_orden ON ordenes;
DROP FUNCTION IF EXISTS set_numero_orden();

-- 2. Eliminar secuencia anterior si existe
DROP SEQUENCE IF EXISTS ordenes_numero_seq;

-- 3. Crear nueva secuencia (empezar desde 1000)
CREATE SEQUENCE ordenes_numero_seq START 1000;

-- 4. Crear función para asignar número automáticamente
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

-- 5. Crear trigger
CREATE TRIGGER trigger_set_numero_orden
    BEFORE INSERT ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION set_numero_orden();

-- 6. Verificar que todo está configurado
SELECT 
    'Secuencia creada' as status,
    last_value as ultimo_valor
FROM ordenes_numero_seq;

-- 7. Verificar que la función existe
SELECT 
    'Función creada' as status,
    proname as nombre_funcion,
    prorettype::regtype as tipo_retorno
FROM pg_proc 
WHERE proname = 'set_numero_orden';

-- 8. Verificar que el trigger existe
SELECT 
    'Trigger creado' as status,
    tgname as nombre_trigger,
    tgrelid::regclass as tabla
FROM pg_trigger 
WHERE tgname = 'trigger_set_numero_orden';
