-- Agregar columna de foto de perfil a la tabla usuarios
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS foto_perfil TEXT;

-- Comentario para claridad
COMMENT ON COLUMN public.usuarios.foto_perfil IS 'URL de la foto de perfil del usuario en Supabase Storage';

-- Verificar las columnas
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'usuarios' 
AND column_name = 'foto_perfil';