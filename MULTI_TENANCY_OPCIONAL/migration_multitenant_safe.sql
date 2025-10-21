-- ============================================
-- MIGRACIÓN MULTI-TENANCY SEGURA
-- NO DESTRUCTIVA - NO ROMPE DATOS EXISTENTES
-- ============================================

-- PASO 1: Crear tabla de tenants (empresas/clientes)
-- ============================================
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  email_contacto TEXT,
  telefono TEXT,
  logo_url TEXT,
  color_primario TEXT DEFAULT '#37474F',
  color_secundario TEXT DEFAULT '#FF9800',
  activo BOOLEAN DEFAULT true,
  fecha_creacion TIMESTAMPTZ DEFAULT NOW(),
  fecha_expiracion TIMESTAMPTZ,
  plan TEXT DEFAULT 'basico',
  limite_ordenes INT DEFAULT 10000,
  limite_usuarios INT DEFAULT 50,
  configuracion JSONB DEFAULT '{}'::jsonb,
  notas TEXT
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON tenants(slug);
CREATE INDEX IF NOT EXISTS idx_tenants_activo ON tenants(activo);

-- Habilitar RLS en tenants
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- Política: Solo super-admins pueden ver todos los tenants
CREATE POLICY "super_admin_full_access" ON tenants
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM usuarios 
      WHERE usuarios.auth_id = auth.uid() 
      AND usuarios.rol = 'super_admin'
    )
  );

-- Política: Usuarios normales ven solo su tenant
CREATE POLICY "users_see_own_tenant" ON tenants
  FOR SELECT
  USING (
    id = (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid
  );


-- PASO 2: Insertar tenant DEFAULT para datos existentes
-- ============================================
INSERT INTO tenants (id, nombre, slug, email_contacto, telefono, activo, plan)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'J Alvarez Express (Original)',
  'jalvarez-original',
  'admin@jalvarez.com',
  '+1-305-123-4567',
  true,
  'enterprise'
) ON CONFLICT (slug) DO NOTHING;


-- PASO 3: Agregar columna tenant_id a todas las tablas (NULLABLE primero)
-- ============================================

-- Usuarios
ALTER TABLE usuarios 
  ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Ordenes
ALTER TABLE ordenes 
  ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Emisores
ALTER TABLE emisores 
  ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Destinatarios
ALTER TABLE destinatarios 
  ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Conversaciones Soporte
ALTER TABLE conversaciones_soporte 
  ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Mensajes Soporte
ALTER TABLE mensajes_soporte 
  ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;

-- Configuracion Envios
ALTER TABLE configuracion_envios 
  ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;


-- PASO 4: Asignar tenant DEFAULT a todos los datos existentes
-- ============================================

UPDATE usuarios 
SET tenant_id = '00000000-0000-0000-0000-000000000001'::uuid 
WHERE tenant_id IS NULL;

UPDATE ordenes 
SET tenant_id = '00000000-0000-0000-0000-000000000001'::uuid 
WHERE tenant_id IS NULL;

UPDATE emisores 
SET tenant_id = '00000000-0000-0000-0000-000000000001'::uuid 
WHERE tenant_id IS NULL;

UPDATE destinatarios 
SET tenant_id = '00000000-0000-0000-0000-000000000001'::uuid 
WHERE tenant_id IS NULL;

UPDATE conversaciones_soporte 
SET tenant_id = '00000000-0000-0000-0000-000000000001'::uuid 
WHERE tenant_id IS NULL;

UPDATE mensajes_soporte 
SET tenant_id = '00000000-0000-0000-0000-000000000001'::uuid 
WHERE tenant_id IS NULL;

UPDATE configuracion_envios 
SET tenant_id = '00000000-0000-0000-0000-000000000001'::uuid 
WHERE tenant_id IS NULL;


-- PASO 5: Crear índices para performance
-- ============================================

CREATE INDEX IF NOT EXISTS idx_usuarios_tenant ON usuarios(tenant_id);
CREATE INDEX IF NOT EXISTS idx_ordenes_tenant ON ordenes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_emisores_tenant ON emisores(tenant_id);
CREATE INDEX IF NOT EXISTS idx_destinatarios_tenant ON destinatarios(tenant_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_tenant ON conversaciones_soporte(tenant_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_tenant ON mensajes_soporte(tenant_id);
CREATE INDEX IF NOT EXISTS idx_config_tenant ON configuracion_envios(tenant_id);


-- PASO 6: Funciones helper para multi-tenancy
-- ============================================

-- Función para obtener tenant_id del usuario actual
CREATE OR REPLACE FUNCTION get_current_tenant_id()
RETURNS UUID AS $$
DECLARE
  tenant_id_val UUID;
BEGIN
  -- Primero intentar desde JWT metadata
  tenant_id_val := (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid;
  
  -- Si no existe en JWT, buscar en tabla usuarios
  IF tenant_id_val IS NULL THEN
    SELECT u.tenant_id INTO tenant_id_val
    FROM usuarios u
    WHERE u.auth_id = auth.uid()
    LIMIT 1;
  END IF;
  
  RETURN tenant_id_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si el usuario es super-admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM usuarios 
    WHERE auth_id = auth.uid() 
    AND rol = 'super_admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- PASO 7: Actualizar políticas RLS para multi-tenancy (OPCIONAL - COMENTADO POR SEGURIDAD)
-- ============================================
-- DESCOMENTAR SOLO DESPUÉS DE VERIFICAR QUE TODO FUNCIONA

/*
-- Ejemplo para tabla ordenes:
DROP POLICY IF EXISTS "Users can view their orders" ON ordenes;
DROP POLICY IF EXISTS "Admins can view all orders" ON ordenes;

CREATE POLICY "tenant_isolation_ordenes_select" ON ordenes
  FOR SELECT
  USING (
    -- Super-admin ve todo
    is_super_admin() OR
    -- Usuarios normales ven solo su tenant
    tenant_id = get_current_tenant_id()
  );

CREATE POLICY "tenant_isolation_ordenes_insert" ON ordenes
  FOR INSERT
  WITH CHECK (tenant_id = get_current_tenant_id());

-- Replicar para todas las tablas después de testing
*/


-- PASO 8: Crear usuario super-admin
-- ============================================
-- IMPORTANTE: Ejecutar esto DESPUÉS de crear el usuario en Supabase Auth

-- Primero crear usuario en Supabase Auth Dashboard:
-- Email: admin@administrador.com
-- Password: Admin123!
-- User Metadata: { "is_super_admin": true }

-- Luego ejecutar esto (reemplazar 'AUTH_ID_AQUI' con el ID real del usuario):
/*
INSERT INTO usuarios (auth_id, email, nombre, rol, activo, tenant_id)
VALUES (
  'AUTH_ID_AQUI',
  'admin@administrador.com',
  'Super Administrador',
  'super_admin',
  true,
  '00000000-0000-0000-0000-000000000001'::uuid
) ON CONFLICT (auth_id) DO UPDATE SET rol = 'super_admin';
*/


-- PASO 9: Crear vista de estadísticas por tenant
-- ============================================
CREATE OR REPLACE VIEW tenant_stats AS
SELECT 
  t.id,
  t.nombre,
  t.slug,
  t.activo,
  t.plan,
  COUNT(DISTINCT u.id) as total_usuarios,
  COUNT(DISTINCT o.id) as total_ordenes,
  COUNT(DISTINCT CASE WHEN o.estado = 'ACTIVA' THEN o.id END) as ordenes_activas,
  COUNT(DISTINCT CASE WHEN o.estado = 'ENTREGADO' THEN o.id END) as ordenes_entregadas,
  COUNT(DISTINCT e.id) as total_emisores,
  COUNT(DISTINCT d.id) as total_destinatarios
FROM tenants t
LEFT JOIN usuarios u ON u.tenant_id = t.id
LEFT JOIN ordenes o ON o.tenant_id = t.id
LEFT JOIN emisores e ON e.tenant_id = t.id
LEFT JOIN destinatarios d ON d.tenant_id = t.id
GROUP BY t.id, t.nombre, t.slug, t.activo, t.plan;

-- Permitir que super-admins vean las estadísticas
GRANT SELECT ON tenant_stats TO authenticated;


-- ============================================
-- FIN DE LA MIGRACIÓN
-- ============================================

-- VERIFICACIÓN: Ejecutar para confirmar que todo funcionó
SELECT 
  'tenants' as tabla, COUNT(*) as registros FROM tenants
UNION ALL
SELECT 'usuarios con tenant_id', COUNT(*) FROM usuarios WHERE tenant_id IS NOT NULL
UNION ALL
SELECT 'ordenes con tenant_id', COUNT(*) FROM ordenes WHERE tenant_id IS NOT NULL;

