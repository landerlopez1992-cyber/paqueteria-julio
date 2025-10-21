-- Agregar columnas de información del destinatario a la tabla ordenes
ALTER TABLE public.ordenes 
ADD COLUMN IF NOT EXISTS telefono_destinatario TEXT,
ADD COLUMN IF NOT EXISTS provincia_destino TEXT,
ADD COLUMN IF NOT EXISTS municipio_destino TEXT,
ADD COLUMN IF NOT EXISTS consejo_popular_batey TEXT;

-- Agregar comentarios a las columnas
COMMENT ON COLUMN public.ordenes.telefono_destinatario IS 'Teléfono del destinatario';
COMMENT ON COLUMN public.ordenes.provincia_destino IS 'Provincia del destinatario';
COMMENT ON COLUMN public.ordenes.municipio_destino IS 'Municipio del destinatario';
COMMENT ON COLUMN public.ordenes.consejo_popular_batey IS 'Consejo popular o batey del destinatario';

