-- ============================================
-- VERIFICAR PASSWORD DEL REPARTIDOR
-- ============================================

-- 1. Verificar si el usuario tiene contraseña configurada
SELECT 
  id,
  email,
  encrypted_password IS NOT NULL as has_password,
  created_at,
  email_confirmed_at
FROM auth.users 
WHERE email = 'omar@paqueteria.com';

-- 2. Si no tiene contraseña, necesitamos crear una
-- (Esto se hace desde la interfaz de Supabase o con un script)

-- 3. Verificar que el usuario existe en la tabla usuarios
SELECT 
  u.id,
  u.auth_id,
  u.email,
  u.nombre,
  u.rol,
  u.tenant_id,
  t.nombre as empresa_nombre
FROM usuarios u
LEFT JOIN tenants t ON t.id = u.tenant_id
WHERE u.email = 'omar@paqueteria.com';



