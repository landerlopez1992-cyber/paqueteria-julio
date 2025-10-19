-- Agregar columna foto_perfil a la tabla usuarios
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS foto_perfil TEXT;

-- Crear bucket para fotos de perfil en Supabase Storage
-- Nota: Este comando debe ejecutarse en el dashboard de Supabase Storage
-- INSERT INTO storage.buckets (id, name, public) VALUES ('fotos-perfil', 'fotos-perfil', true);

-- Crear política RLS para el bucket de fotos de perfil
-- Nota: Estas políticas deben crearse en el dashboard de Supabase Storage
-- CREATE POLICY "Usuarios pueden subir sus propias fotos" ON storage.objects
-- FOR INSERT WITH CHECK (bucket_id = 'fotos-perfil' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Usuarios pueden ver sus propias fotos" ON storage.objects
-- FOR SELECT USING (bucket_id = 'fotos-perfil' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Usuarios pueden actualizar sus propias fotos" ON storage.objects
-- FOR UPDATE USING (bucket_id = 'fotos-perfil' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Usuarios pueden eliminar sus propias fotos" ON storage.objects
-- FOR DELETE USING (bucket_id = 'fotos-perfil' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Verificar que la columna se agregó correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'usuarios' AND column_name = 'foto_perfil';
