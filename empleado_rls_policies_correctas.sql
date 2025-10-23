-- =====================================================
-- RLS POLICIES CORRECTAS PARA ROL EMPLEADO
-- (Solo para tablas que SÍ existen)
-- =====================================================

-- 1. Policy para usuarios - EMPLEADO puede ver su propio perfil
DROP POLICY IF EXISTS "Empleados pueden ver su propio perfil" ON usuarios;
CREATE POLICY "Empleados pueden ver su propio perfil" ON usuarios
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = auth_id 
    AND rol = 'EMPLEADO'
  );

-- 2. Policy para órdenes - EMPLEADO puede ver/editar órdenes de su empresa
DROP POLICY IF EXISTS "Empleados pueden gestionar órdenes de su empresa" ON ordenes;
CREATE POLICY "Empleados pueden gestionar órdenes de su empresa" ON ordenes
  FOR ALL
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
    )
  )
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
    )
  );

-- 3. Policy para emisores - EMPLEADO puede ver/editar emisores de su empresa
DROP POLICY IF EXISTS "Empleados pueden gestionar emisores de su empresa" ON emisores;
CREATE POLICY "Empleados pueden gestionar emisores de su empresa" ON emisores
  FOR ALL
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
    )
  )
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
    )
  );

-- 4. Policy para destinatarios - EMPLEADO puede ver/editar destinatarios de su empresa
DROP POLICY IF EXISTS "Empleados pueden gestionar destinatarios de su empresa" ON destinatarios;
CREATE POLICY "Empleados pueden gestionar destinatarios de su empresa" ON destinatarios
  FOR ALL
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
    )
  )
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
    )
  );

-- 5. Policy para repartidores (usuarios con rol REPARTIDOR) - EMPLEADO puede SOLO VER
DROP POLICY IF EXISTS "Empleados pueden ver repartidores de su empresa" ON usuarios;
CREATE POLICY "Empleados pueden ver repartidores de su empresa" ON usuarios
  FOR SELECT
  TO authenticated
  USING (
    rol = 'REPARTIDOR' 
    AND tenant_id IN (
      SELECT tenant_id 
      FROM usuarios 
      WHERE auth_id = auth.uid() 
      AND rol = 'EMPLEADO'
    )
  );

-- 6. Policy para tenants - EMPLEADO NO puede ver/editar información de empresas
-- (No se crea policy, por defecto está bloqueado)

-- =====================================================
-- VERIFICAR POLICIES CREADAS
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

-- =====================================================
-- RESUMEN DE PERMISOS PARA EMPLEADO:
-- =====================================================
-- ✅ PUEDE HACER:
--   - Ver/editar órdenes de su empresa
--   - Ver/editar emisores de su empresa  
--   - Ver/editar destinatarios de su empresa
--   - Ver repartidores de su empresa (solo lectura)
--   - Buscar órdenes
--
-- ❌ NO PUEDE HACER:
--   - Crear/editar repartidores (usuarios)
--   - Crear/editar otros empleados
--   - Ver información de empresas (tenants)
--   - Acceder desde móvil
-- =====================================================
