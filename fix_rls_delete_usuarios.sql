-- Política RLS para permitir a administradores eliminar repartidores
-- Ejecutar este SQL en Supabase SQL Editor

-- 1. Eliminar política anterior si existe
DROP POLICY IF EXISTS "Administradores pueden eliminar repartidores" ON public.usuarios;

-- 2. Crear política para permitir DELETE
CREATE POLICY "Administradores pueden eliminar repartidores"
ON public.usuarios
FOR DELETE
USING (
  -- Verificar si el usuario autenticado es ADMINISTRADOR
  EXISTS (
    SELECT 1 FROM public.usuarios u
    WHERE u.auth_id = auth.uid()
    AND u.rol = 'ADMINISTRADOR'
  )
);

-- 3. Verificar que RLS esté habilitado
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;

-- 4. Verificar políticas existentes
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'usuarios'
ORDER BY policyname;

