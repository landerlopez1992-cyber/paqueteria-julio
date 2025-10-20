-- Script completo para establecer relación entre ordenes y destinatarios
-- Ejecutar en Supabase SQL Editor

-- 1. Verificar estructura actual de las tablas
SELECT 
    'ordenes' as tabla,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'ordenes'
UNION ALL
SELECT 
    'destinatarios' as tabla,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'destinatarios'
ORDER BY tabla, column_name;

-- 2. Crear columna destinatario_id en ordenes si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'ordenes' 
        AND column_name = 'destinatario_id'
    ) THEN
        ALTER TABLE public.ordenes 
        ADD COLUMN destinatario_id UUID;
        
        -- Crear índice para mejorar rendimiento
        CREATE INDEX idx_ordenes_destinatario_id 
        ON public.ordenes(destinatario_id);
        
        RAISE NOTICE 'Columna destinatario_id agregada a tabla ordenes';
    ELSE
        RAISE NOTICE 'Columna destinatario_id ya existe en tabla ordenes';
    END IF;
END $$;

-- 3. Agregar restricción de clave foránea si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'ordenes_destinatario_id_fkey'
        AND table_name = 'ordenes'
    ) THEN
        ALTER TABLE public.ordenes 
        ADD CONSTRAINT ordenes_destinatario_id_fkey 
        FOREIGN KEY (destinatario_id) REFERENCES public.destinatarios(id);
        
        RAISE NOTICE 'Restricción de clave foránea agregada';
    ELSE
        RAISE NOTICE 'Restricción de clave foránea ya existe';
    END IF;
END $$;

-- 4. Verificar la relación creada
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'ordenes'
    AND kcu.column_name = 'destinatario_id';
