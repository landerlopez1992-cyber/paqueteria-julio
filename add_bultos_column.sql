-- Agregar columna cantidad_bultos a la tabla ordenes
ALTER TABLE public.ordenes 
ADD COLUMN IF NOT EXISTS cantidad_bultos INTEGER DEFAULT 1 CHECK (cantidad_bultos > 0);

-- Comentario para la columna
COMMENT ON COLUMN public.ordenes.cantidad_bultos IS 'Cantidad de bultos que componen la orden';

-- Actualizar órdenes existentes para que tengan al menos 1 bulto
UPDATE public.ordenes 
SET cantidad_bultos = 1 
WHERE cantidad_bultos IS NULL;

