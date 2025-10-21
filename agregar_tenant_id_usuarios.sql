-- =====================================================
-- AGREGAR tenant_id A TABLA USUARIOS
-- Aislamiento de repartidores por empresa
-- =====================================================

-- PASO 1: Agregar columna tenant_id a usuarios (si no existe)
ALTER TABLE usuarios 
ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- PASO 2: Asignar tenant_id a usuarios existentes
-- Asignar a la primera empresa (J Alvarez Express SVC) por defecto
UPDATE usuarios 
SET tenant_id = (SELECT id FROM tenants ORDER BY fecha_creacion ASC LIMIT 1)
WHERE tenant_id IS NULL;

-- PASO 3: Crear índice para mejorar performance
CREATE INDEX IF NOT EXISTS idx_usuarios_tenant_id ON usuarios(tenant_id);

-- PASO 4: Ver resultado
SELECT 
  u.email,
  u.nombre,
  u.rol,
  t.nombre as empresa
FROM usuarios u
LEFT JOIN tenants t ON u.tenant_id = t.id
ORDER BY u.rol, u.email;

-- =====================================================
-- VERIFICACIÓN
-- =====================================================
SELECT 
  'Total usuarios' as metrica, 
  COUNT(*) as cantidad 
FROM usuarios
UNION ALL
SELECT 
  'Usuarios con tenant_id', 
  COUNT(*) 
FROM usuarios 
WHERE tenant_id IS NOT NULL
UNION ALL
SELECT 
  'Usuarios sin tenant_id', 
  COUNT(*) 
FROM usuarios 
WHERE tenant_id IS NULL;

