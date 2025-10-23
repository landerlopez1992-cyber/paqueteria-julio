-- =====================================================
-- SOLUCIÓN DE EMERGENCIA: ELIMINAR TODAS LAS POLICIES PROBLEMÁTICAS
-- =====================================================

-- 1. ELIMINAR **TODAS** LAS POLICIES DE LA TABLA USUARIOS
DROP POLICY IF EXISTS "Empleados pueden ver su propio perfil" ON usuarios;
DROP POLICY IF EXISTS "Empleados pueden ver repartidores de su empresa" ON usuarios;
DROP POLICY IF EXISTS "Super Admin puede ver todos los usuarios" ON usuarios;
DROP POLICY IF EXISTS "Administradores pueden ver sus usuarios" ON usuarios;
DROP POLICY IF EXISTS "Administradores pueden crear usuarios" ON usuarios;
DROP POLICY IF EXISTS "Administradores pueden actualizar usuarios" ON usuarios;
DROP POLICY IF EXISTS "Repartidores pueden ver su perfil" ON usuarios;
DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON usuarios;

-- 2. DESHABILITAR RLS EN USUARIOS TEMPORALMENTE (SOLUCIÓN RÁPIDA)
ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;

-- 3. ELIMINAR LAS POLICIES DE EMPLEADO DE OTRAS TABLAS
DROP POLICY IF EXISTS "Empleados pueden gestionar órdenes de su empresa" ON ordenes;
DROP POLICY IF EXISTS "Empleados pueden gestionar emisores de su empresa" ON emisores;
DROP POLICY IF EXISTS "Empleados pueden gestionar destinatarios de su empresa" ON destinatarios;

-- 4. VERIFICAR QUE NO HAY POLICIES EN USUARIOS
SELECT 
  tablename,
  policyname
FROM pg_policies 
WHERE tablename = 'usuarios';

-- 5. VERIFICAR ESTADO DE RLS
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'usuarios';
