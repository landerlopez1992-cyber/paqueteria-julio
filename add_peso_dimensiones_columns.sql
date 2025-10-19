-- Agregar columnas de peso y dimensiones a la tabla ordenes
-- PESO en LIBRAS (lb), no kilogramos

ALTER TABLE public.ordenes 
ADD COLUMN IF NOT EXISTS peso DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS largo DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS ancho DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS alto DECIMAL(10, 2);

-- Comentarios para claridad
COMMENT ON COLUMN public.ordenes.peso IS 'Peso del paquete en libras (lb)';
COMMENT ON COLUMN public.ordenes.largo IS 'Largo del paquete en centímetros (cm)';
COMMENT ON COLUMN public.ordenes.ancho IS 'Ancho del paquete en centímetros (cm)';
COMMENT ON COLUMN public.ordenes.alto IS 'Alto del paquete en centímetros (cm)';

-- Verificar las columnas
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ordenes' 
AND column_name IN ('peso', 'largo', 'ancho', 'alto', 'cantidad_bultos');

