-- =====================================================
-- AGREGAR ROL EMPLEADO A LA BASE DE DATOS
-- =====================================================

-- 1. Actualizar la constraint de roles para incluir EMPLEADO
ALTER TABLE usuarios DROP CONSTRAINT IF EXISTS usuarios_rol_check;

ALTER TABLE usuarios ADD CONSTRAINT usuarios_rol_check 
CHECK (rol IN ('SUPER_ADMIN', 'ADMINISTRADOR', 'REPARTIDOR', 'EMPLEADO'));

-- 2. Crear un empleado de ejemplo (opcional)
-- INSERT INTO usuarios (
--   id,
--   nombre,
--   email,
--   rol,
--   tenant_id,
--   created_at,
--   updated_at
-- ) VALUES (
--   gen_random_uuid(),
--   'Empleado Ejemplo',
--   'empleado@ejemplo.com',
--   'EMPLEADO',
--   'TENANT_ID_DE_LA_EMPRESA', -- Reemplazar con el tenant_id real
--   NOW(),
--   NOW()
-- );

-- 3. Verificar que la constraint se aplicó correctamente
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'usuarios'::regclass 
AND conname = 'usuarios_rol_check';

-- 4. Verificar roles existentes
SELECT DISTINCT rol FROM usuarios ORDER BY rol;

-- =====================================================
-- NOTAS IMPORTANTES:
-- =====================================================
-- 1. El rol EMPLEADO solo puede acceder desde WEB (no móvil)
-- 2. Los empleados tienen acceso limitado:
--    - Órdenes (ver, editar, administrar)
--    - Emisores/Destinatarios (ver, editar)
--    - Chat de Soporte (atender repartidores)
--    - Buscar Órdenes
-- 3. NO pueden:
--    - Crear repartidores
--    - Crear otros empleados
--    - Acceder a configuración de empresa
--    - Acceder desde móvil
-- =====================================================
