-- ============================================
-- AGREGAR COLUMNA DIRECCIÓN A TENANTS
-- ============================================

-- Agregar columna direccion si no existe
ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS direccion TEXT;

-- Agregar otras columnas útiles para información de empresa
ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS sitio_web TEXT;

ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS descripcion TEXT;

-- Verificar que las columnas se agregaron correctamente
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'tenants'
AND column_name IN ('direccion', 'sitio_web', 'descripcion')
ORDER BY column_name;



