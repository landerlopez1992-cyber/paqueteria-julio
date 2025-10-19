-- PASO 1: Agregar columnas y limpiar funciones anteriores

-- 1. Agregar columnas si no existen
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS numero_orden TEXT;
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS es_urgente BOOLEAN DEFAULT FALSE;

-- 2. Eliminar triggers anteriores
DROP TRIGGER IF EXISTS trigger_asignar_numero_orden ON ordenes;
DROP TRIGGER IF EXISTS set_numero_orden ON ordenes;

-- 3. Eliminar funciones anteriores
DROP FUNCTION IF EXISTS asignar_numero_orden();
DROP FUNCTION IF EXISTS generar_numero_orden();

-- 4. Eliminar secuencia anterior
DROP SEQUENCE IF EXISTS ordenes_numero_seq;

-- 5. Verificar que las columnas existen
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'ordenes' 
AND column_name IN ('numero_orden', 'es_urgente')
ORDER BY column_name;


