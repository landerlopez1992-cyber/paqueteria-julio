-- Script para actualizar la tabla destinatarios existente
-- Agregar las nuevas columnas municipio y consejo_popular_batey

-- Agregar columna municipio
ALTER TABLE public.destinatarios 
ADD COLUMN IF NOT EXISTS municipio TEXT;

-- Agregar columna consejo_popular_batey
ALTER TABLE public.destinatarios 
ADD COLUMN IF NOT EXISTS consejo_popular_batey TEXT;

-- Eliminar columna ciudad si existe (ya no la necesitamos)
ALTER TABLE public.destinatarios 
DROP COLUMN IF EXISTS ciudad;

-- Eliminar columna codigo_postal si existe (ya no la necesitamos)
ALTER TABLE public.destinatarios 
DROP COLUMN IF EXISTS codigo_postal;

-- Comentarios para las nuevas columnas
COMMENT ON COLUMN public.destinatarios.municipio IS 'Municipio del destinatario';
COMMENT ON COLUMN public.destinatarios.consejo_popular_batey IS 'Consejo Popular o Batey del destinatario';

-- Crear índice para municipio
CREATE INDEX IF NOT EXISTS idx_destinatarios_municipio ON public.destinatarios(municipio);

-- Actualizar datos existentes con valores por defecto
UPDATE public.destinatarios 
SET municipio = 'Sin especificar'
WHERE municipio IS NULL;

UPDATE public.destinatarios 
SET consejo_popular_batey = 'Sin especificar'
WHERE consejo_popular_batey IS NULL;

-- Verificar que las columnas se agregaron correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'destinatarios' 
AND table_schema = 'public'
ORDER BY ordinal_position;
