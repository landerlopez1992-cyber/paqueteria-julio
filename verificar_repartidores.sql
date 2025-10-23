-- ============================================
-- VERIFICAR REPARTIDORES Y SU TENANT_ID
-- ============================================

-- 1. Ver todos los usuarios con rol REPARTIDOR
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
WHERE u.rol = 'REPARTIDOR'
ORDER BY u.nombre;

-- 2. Verificar que todos los repartidores tienen tenant_id
SELECT 
  'Total Repartidores' as metrica,
  COUNT(*) as cantidad
FROM usuarios
WHERE rol = 'REPARTIDOR'
UNION ALL
SELECT 
  'Repartidores con tenant_id',
  COUNT(*)
FROM usuarios
WHERE rol = 'REPARTIDOR' AND tenant_id IS NOT NULL
UNION ALL
SELECT 
  'Repartidores sin tenant_id',
  COUNT(*)
FROM usuarios
WHERE rol = 'REPARTIDOR' AND tenant_id IS NULL;

-- 3. Si hay repartidores sin tenant_id, asignarles el tenant por defecto
UPDATE usuarios 
SET tenant_id = 'd755974e-a60b-4de4-8c8a-09833c4464cb'::uuid
WHERE rol = 'REPARTIDOR' AND tenant_id IS NULL;

-- 4. Verificar después del update
SELECT 
  'Después del update - Total Repartidores' as metrica,
  COUNT(*) as cantidad
FROM usuarios
WHERE rol = 'REPARTIDOR'
UNION ALL
SELECT 
  'Después del update - Con tenant_id',
  COUNT(*)
FROM usuarios
WHERE rol = 'REPARTIDOR' AND tenant_id IS NOT NULL;



