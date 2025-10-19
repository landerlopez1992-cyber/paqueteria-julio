-- Agregar columnas faltantes a la tabla emisores
ALTER TABLE public.emisores 
ADD COLUMN IF NOT EXISTS telefono TEXT,
ADD COLUMN IF NOT EXISTS direccion TEXT,
ADD COLUMN IF NOT EXISTS empresa TEXT;

-- Comentarios para las columnas
COMMENT ON COLUMN public.emisores.telefono IS 'Número de teléfono del emisor';
COMMENT ON COLUMN public.emisores.direccion IS 'Dirección física del emisor';
COMMENT ON COLUMN public.emisores.empresa IS 'Nombre de la empresa del emisor';

-- Verificar que las políticas RLS estén configuradas para emisores
-- Crear política que permita a usuarios autenticados insertar emisores
DROP POLICY IF EXISTS "Emisores: authenticated can insert" ON public.emisores;
CREATE POLICY "Emisores: authenticated can insert" 
ON public.emisores 
FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Crear política que permita a usuarios autenticados actualizar emisores
DROP POLICY IF EXISTS "Emisores: authenticated can update" ON public.emisores;
CREATE POLICY "Emisores: authenticated can update" 
ON public.emisores 
FOR UPDATE 
USING (auth.role() = 'authenticated') 
WITH CHECK (auth.role() = 'authenticated');

-- Crear política que permita a usuarios autenticados leer emisores
DROP POLICY IF EXISTS "Emisores: authenticated can read" ON public.emisores;
CREATE POLICY "Emisores: authenticated can read" 
ON public.emisores 
FOR SELECT 
USING (auth.role() = 'authenticated');

-- Crear política que permita a usuarios autenticados eliminar emisores
DROP POLICY IF EXISTS "Emisores: authenticated can delete" ON public.emisores;
CREATE POLICY "Emisores: authenticated can delete" 
ON public.emisores 
FOR DELETE 
USING (auth.role() = 'authenticated');
