-- Agregar campo de provincias asignadas a la tabla usuarios
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS provincias_asignadas TEXT;

-- Comentario para el campo
COMMENT ON COLUMN public.usuarios.provincias_asignadas IS 'Provincias de Cuba asignadas al repartidor, separadas por comas';

-- Actualizar usuarios existentes con algunas provincias de ejemplo
UPDATE public.usuarios 
SET provincias_asignadas = 'La Habana,Matanzas' 
WHERE rol = 'REPARTIDOR' AND provincias_asignadas IS NULL;
