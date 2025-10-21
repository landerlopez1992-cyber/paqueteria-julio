-- Crear tabla tenants y empresa de prueba
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  email_contacto TEXT,
  telefono TEXT,
  logo_url TEXT,
  activo BOOLEAN DEFAULT true,
  fecha_creacion TIMESTAMPTZ DEFAULT NOW(),
  plan TEXT DEFAULT 'basico',
  notas TEXT
);

-- Insertar empresa de prueba
INSERT INTO tenants (nombre, slug, email_contacto, telefono, activo, plan, notas)
VALUES (
  'J Alvarez Express SVC',
  'jalvarez-express',
  'admin@paqueteria.com',
  '+1-305-123-4567',
  true,
  'enterprise',
  'Empresa principal de paquetería'
) ON CONFLICT (slug) DO NOTHING;

-- Crear vista de estadísticas básica
CREATE OR REPLACE VIEW tenant_stats AS
SELECT 
  t.id,
  t.nombre,
  t.slug,
  t.activo,
  t.plan,
  0 as total_usuarios,
  0 as total_ordenes,
  0 as ordenes_activas,
  0 as ordenes_entregadas,
  0 as total_emisores,
  0 as total_destinatarios
FROM tenants t;

-- Verificar
SELECT * FROM tenants;
