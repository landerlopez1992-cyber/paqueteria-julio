-- =====================================================
-- ARREGLAR RECURSIÓN INFINITA EN RLS POLICIES
-- =====================================================

-- 1. ELIMINAR TODAS LAS POLICIES PROBLEMÁTICAS
DROP POLICY IF EXISTS "Empleados pueden ver su propio perfil" ON usuarios;
DROP POLICY IF EXISTS "Empleados pueden gestionar órdenes de su empresa" ON ordenes;
DROP POLICY IF EXISTS "Empleados pueden gestionar emisores de su empresa" ON emisores;
DROP POLICY IF EXISTS "Empleados pueden gestionar destinatarios de su empresa" ON destinatarios;
DROP POLICY IF EXISTS "Empleados pueden ver repartidores de su empresa" ON usuarios;

-- 2. CREAR POLICIES SIMPLES SIN RECURSIÓN
-- Policy para usuarios - EMPLEADO puede ver su propio perfil (SIN subquery)
CREATE POLICY "Empleados pueden ver su propio perfil" ON usuarios
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = auth_id 
    AND rol = 'EMPLEADO'
  );

-- Policy para órdenes - EMPLEADO puede ver/editar órdenes de su empresa (SIN subquery)
CREATE POLICY "Empleados pueden gestionar órdenes de su empresa" ON ordenes
  FOR ALL
  TO authenticated
  USING (
    tenant_id = (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
      LIMIT 1
    )
  )
  WITH CHECK (
    tenant_id = (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
      LIMIT 1
    )
  );

-- Policy para emisores - EMPLEADO puede ver/editar emisores de su empresa (SIN subquery)
CREATE POLICY "Empleados pueden gestionar emisores de su empresa" ON emisores
  FOR ALL
  TO authenticated
  USING (
    tenant_id = (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
      LIMIT 1
    )
  )
  WITH CHECK (
    tenant_id = (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
      LIMIT 1
    )
  );

-- Policy para destinatarios - EMPLEADO puede ver/editar destinatarios de su empresa (SIN subquery)
CREATE POLICY "Empleados pueden gestionar destinatarios de su empresa" ON destinatarios
  FOR ALL
  TO authenticated
  USING (
    tenant_id = (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
      LIMIT 1
    )
  )
  WITH CHECK (
    tenant_id = (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
      LIMIT 1
    )
  );

-- Policy para repartidores (usuarios con rol REPARTIDOR) - EMPLEADO puede SOLO VER (SIN subquery)
CREATE POLICY "Empleados pueden ver repartidores de su empresa" ON usuarios
  FOR SELECT
  TO authenticated
  USING (
    rol = 'REPARTIDOR' 
    AND tenant_id = (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
      LIMIT 1
    )
  );

-- =====================================================
-- VERIFICAR QUE NO HAY RECURSIÓN
-- =====================================================

-- Verificar que las policies se crearon correctamente
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
WHERE policyname LIKE '%Empleado%'
ORDER BY tablename, policyname;
