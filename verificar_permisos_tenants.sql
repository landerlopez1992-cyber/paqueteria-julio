-- ============================================
-- VERIFICAR Y ARREGLAR PERMISOS RLS EN TENANTS
-- ============================================

-- 1. Verificar si RLS está habilitado en tenants
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'tenants';

-- 2. Ver políticas actuales
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'tenants';

-- 3. DESHABILITAR RLS temporalmente para debug
ALTER TABLE tenants DISABLE ROW LEVEL SECURITY;

-- 4. Verificar que ahora está deshabilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'tenants';

-- 5. Verificar que los datos son accesibles
SELECT COUNT(*) as total_tenants FROM tenants;

-- 6. Ver todos los tenants
SELECT * FROM tenants ORDER BY fecha_creacion DESC;




