-- Agregar columnas faltantes a la tabla usuarios
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS telefono TEXT,
ADD COLUMN IF NOT EXISTS direccion TEXT,
ADD COLUMN IF NOT EXISTS provincias_asignadas TEXT;

-- Comentarios para las columnas
COMMENT ON COLUMN public.usuarios.telefono IS 'Número de teléfono del usuario';
COMMENT ON COLUMN public.usuarios.direccion IS 'Dirección física del usuario';
COMMENT ON COLUMN public.usuarios.provincias_asignadas IS 'Provincias de Cuba asignadas al repartidor, separadas por comas';

-- Actualizar usuarios existentes con datos de ejemplo
UPDATE public.usuarios 
SET 
  telefono = CASE 
    WHEN email = 'admin@paqueteria.com' THEN '+53 5 123-4567'
    WHEN email = 'repartidor@paqueteria.com' THEN '+53 5 987-6543'
    ELSE NULL
  END,
  direccion = CASE 
    WHEN email = 'admin@paqueteria.com' THEN 'Calle 23 #456, Vedado, La Habana'
    WHEN email = 'repartidor@paqueteria.com' THEN 'Avenida 5ta #123, Miramar, La Habana'
    ELSE NULL
  END,
  provincias_asignadas = CASE 
    WHEN rol = 'REPARTIDOR' THEN 'La Habana,Matanzas'
    ELSE NULL
  END
WHERE telefono IS NULL OR direccion IS NULL OR (rol = 'REPARTIDOR' AND provincias_asignadas IS NULL);
