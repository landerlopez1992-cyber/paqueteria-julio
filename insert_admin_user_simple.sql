-- ============================================
-- INSERTAR USUARIO ADMINISTRADOR SIMPLE
-- ============================================

-- Verificar si el usuario ya existe
SELECT email, nombre, rol FROM public.usuarios WHERE email = 'admin@paqueteria.com';

-- Si no existe, insertarlo
INSERT INTO public.usuarios (
  email,
  nombre,
  telefono,
  rol,
  created_at,
  updated_at
) VALUES (
  'admin@paqueteria.com',
  'Administrador',
  '+53 123456789',
  'ADMINISTRADOR',
  now(),
  now()
) ON CONFLICT (email) DO NOTHING;

-- Verificar que se insertó correctamente
SELECT email, nombre, rol, created_at FROM public.usuarios WHERE email = 'admin@paqueteria.com';


