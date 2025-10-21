-- =====================================================
-- VERIFICAR QUE TODAS LAS TABLAS TIENEN tenant_id
-- =====================================================

-- Verificar estructura de tablas principales
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('usuarios', 'ordenes', 'emisores', 'destinatarios', 'conversaciones_soporte', 'mensajes_soporte', 'configuracion_envios')
  AND column_name = 'tenant_id'
ORDER BY table_name;

-- =====================================================
-- Si alguna tabla NO tiene tenant_id, ejecutar esto:
-- =====================================================

-- Agregar tenant_id a TODAS las tablas (si no existe)
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
ALTER TABLE emisores ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
ALTER TABLE destinatarios ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
ALTER TABLE conversaciones_soporte ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
ALTER TABLE mensajes_soporte ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
ALTER TABLE configuracion_envios ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Asignar tenant por defecto a datos existentes
UPDATE ordenes SET tenant_id = (SELECT id FROM tenants ORDER BY fecha_creacion ASC LIMIT 1) WHERE tenant_id IS NULL;
UPDATE emisores SET tenant_id = (SELECT id FROM tenants ORDER BY fecha_creacion ASC LIMIT 1) WHERE tenant_id IS NULL;
UPDATE destinatarios SET tenant_id = (SELECT id FROM tenants ORDER BY fecha_creacion ASC LIMIT 1) WHERE tenant_id IS NULL;
UPDATE conversaciones_soporte SET tenant_id = (SELECT id FROM tenants ORDER BY fecha_creacion ASC LIMIT 1) WHERE tenant_id IS NULL;
UPDATE mensajes_soporte SET tenant_id = (SELECT id FROM tenants ORDER BY fecha_creacion ASC LIMIT 1) WHERE tenant_id IS NULL;
UPDATE configuracion_envios SET tenant_id = (SELECT id FROM tenants ORDER BY fecha_creacion ASC LIMIT 1) WHERE tenant_id IS NULL;

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_ordenes_tenant ON ordenes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_emisores_tenant ON emisores(tenant_id);
CREATE INDEX IF NOT EXISTS idx_destinatarios_tenant ON destinatarios(tenant_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_tenant ON conversaciones_soporte(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_tenant ON mensajes_soporte(tenant_id);
CREATE INDEX IF NOT EXISTS idx_config_tenant ON configuracion_envios(tenant_id);

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================
SELECT 
  'ordenes' as tabla, 
  COUNT(*) as total,
  COUNT(tenant_id) as con_tenant,
  COUNT(*) - COUNT(tenant_id) as sin_tenant
FROM ordenes
UNION ALL
SELECT 'emisores', COUNT(*), COUNT(tenant_id), COUNT(*) - COUNT(tenant_id) FROM emisores
UNION ALL
SELECT 'destinatarios', COUNT(*), COUNT(tenant_id), COUNT(*) - COUNT(tenant_id) FROM destinatarios
UNION ALL
SELECT 'usuarios', COUNT(*), COUNT(tenant_id), COUNT(*) - COUNT(tenant_id) FROM usuarios
UNION ALL
SELECT 'conversaciones', COUNT(*), COUNT(tenant_id), COUNT(*) - COUNT(tenant_id) FROM conversaciones_soporte
UNION ALL
SELECT 'mensajes', COUNT(*), COUNT(tenant_id), COUNT(*) - COUNT(tenant_id) FROM mensajes_soporte
UNION ALL
SELECT 'config_envios', COUNT(*), COUNT(tenant_id), COUNT(*) - COUNT(tenant_id) FROM configuracion_envios;

