-- PASO 3: Crear secuencia, función y trigger para nuevas órdenes

-- 1. Crear secuencia (empezar desde 1000)
CREATE SEQUENCE ordenes_numero_seq START 1000;

-- 2. Crear función para asignar número automáticamente
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

-- 3. Crear trigger
CREATE TRIGGER trigger_set_numero_orden
    BEFORE INSERT ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION set_numero_orden();

-- 4. Verificar que todo está configurado
SELECT 
    'Secuencia creada' as status,
    last_value as ultimo_valor
FROM ordenes_numero_seq;
