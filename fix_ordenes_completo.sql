-- SCRIPT COMPLETO PARA ARREGLAR LA TABLA ORDENES
-- Ejecutar este script completo en una sola vez

-- PASO 1: Agregar columnas si no existen
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS numero_orden TEXT;
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS es_urgente BOOLEAN DEFAULT FALSE;
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS notas TEXT;

-- PASO 2: Limpiar funciones, triggers y secuencias anteriores
DROP TRIGGER IF EXISTS trigger_set_numero_orden ON ordenes;
DROP TRIGGER IF EXISTS set_numero_orden ON ordenes;
DROP TRIGGER IF EXISTS trigger_asignar_numero_orden ON ordenes;
DROP FUNCTION IF EXISTS set_numero_orden();
DROP FUNCTION IF EXISTS asignar_numero_orden();
DROP FUNCTION IF EXISTS generar_numero_orden();
DROP SEQUENCE IF EXISTS ordenes_numero_seq;

-- PASO 3: Actualizar órdenes existentes con números secuenciales
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

-- PASO 4: Crear nueva secuencia
CREATE SEQUENCE ordenes_numero_seq START 1000;

-- PASO 5: Crear función para asignar número automáticamente
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

-- PASO 6: Crear trigger
CREATE TRIGGER trigger_set_numero_orden
    BEFORE INSERT ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION set_numero_orden();

-- PASO 7: Verificar que todo está configurado correctamente
SELECT 
    'VERIFICACIÓN COMPLETA' as titulo,
    '' as separador;

-- Verificar columnas
SELECT 
    'Columnas agregadas:' as status,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes' 
AND column_name IN ('numero_orden', 'es_urgente', 'notas')
ORDER BY column_name;

-- Verificar secuencia
SELECT 
    'Secuencia creada:' as status,
    last_value as ultimo_valor
FROM ordenes_numero_seq;

-- Verificar función
SELECT 
    'Función creada:' as status,
    proname as nombre_funcion,
    prorettype::regtype as tipo_retorno
FROM pg_proc 
WHERE proname = 'set_numero_orden';

-- Verificar trigger
SELECT 
    'Trigger creado:' as status,
    tgname as nombre_trigger,
    tgrelid::regclass as tabla
FROM pg_trigger 
WHERE tgname = 'trigger_set_numero_orden';

-- Mostrar algunas órdenes de ejemplo
SELECT 
    'Órdenes actualizadas:' as status,
    numero_orden,
    emisor_nombre,
    destinatario_nombre,
    estado,
    es_urgente,
    created_at
FROM ordenes 
ORDER BY created_at DESC 
LIMIT 5;


