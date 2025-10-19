-- Agregar columna foto_url a la tabla usuarios
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS foto_url TEXT;

-- Comentario para la columna
COMMENT ON COLUMN public.usuarios.foto_url IS 'URL de la foto de perfil del usuario en Supabase Storage';
