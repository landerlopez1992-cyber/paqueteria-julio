-- ============================================
-- CREAR USUARIO ADMINISTRADOR
-- ============================================

-- Insertar usuario administrador en la tabla usuarios
INSERT INTO public.usuarios (
  id,
  email,
  nombre,
  telefono,
  rol,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'admin@paqueteria.com',
  'Administrador',
  '+53 123456789',
  'ADMINISTRADOR',
  now(),
  now()
) ON CONFLICT (email) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  telefono = EXCLUDED.telefono,
  rol = EXCLUDED.rol,
  updated_at = now();

-- Verificar que se creó correctamente
SELECT 
  id,
  email,
  nombre,
  telefono,
  rol,
  created_at
FROM public.usuarios 
WHERE email = 'admin@paqueteria.com';

-- También crear algunos repartidores de ejemplo
INSERT INTO public.usuarios (
  id,
  email,
  nombre,
  telefono,
  rol,
  created_at,
  updated_at
) VALUES 
(
  gen_random_uuid(),
  'repartidor1@paqueteria.com',
  'Juan Repartidor',
  '+53 111111111',
  'REPARTIDOR',
  now(),
  now()
),
(
  gen_random_uuid(),
  'repartidor2@paqueteria.com',
  'María Repartidora',
  '+53 222222222',
  'REPARTIDOR',
  now(),
  now()
)
ON CONFLICT (email) DO UPDATE SET
  nombre = EXCLUDED.nombre,
  telefono = EXCLUDED.telefono,
  rol = EXCLUDED.rol,
  updated_at = now();

-- Verificar todos los usuarios creados
SELECT 
  email,
  nombre,
  rol,
  created_at
FROM public.usuarios 
ORDER BY rol, nombre;


