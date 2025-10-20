-- Script para establecer relación entre ordenes y destinatarios
-- Ejecutar en Supabase SQL Editor

-- 1. Primero, verificar si existe la columna destinatario_id en ordenes
-- Si no existe, la creamos
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ordenes' 
        AND column_name = 'destinatario_id'
    ) THEN
        ALTER TABLE public.ordenes 
        ADD COLUMN destinatario_id UUID REFERENCES public.destinatarios(id);
    END IF;
END $$;

-- 2. Crear índice para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_ordenes_destinatario_id 
ON public.ordenes(destinatario_id);

-- 3. Verificar la estructura actual
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('ordenes', 'destinatarios')
ORDER BY table_name, ordinal_position;
