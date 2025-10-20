-- Script para habilitar Realtime en tablas de chat
-- Ejecutar en Supabase SQL Editor

-- 1. Habilitar realtime en las tablas de chat
ALTER publication supabase_realtime ADD TABLE public.conversaciones_soporte;
ALTER publication supabase_realtime ADD TABLE public.mensajes_soporte;

-- 2. Verificar que las políticas RLS permitan SELECT para realtime
-- Política para conversaciones_soporte
DROP POLICY IF EXISTS "Repartidores pueden ver sus conversaciones" ON public.conversaciones_soporte;
CREATE POLICY "Repartidores pueden ver sus conversaciones"
ON public.conversaciones_soporte
FOR SELECT
USING (
  repartidor_auth_id = auth.uid()
  OR
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Admins pueden ver todas las conversaciones" ON public.conversaciones_soporte;
CREATE POLICY "Admins pueden ver todas las conversaciones"
ON public.conversaciones_soporte
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios
    WHERE usuarios.auth_id = auth.uid()
    AND usuarios.role = 'ADMIN'
  )
);

-- Política para mensajes_soporte
DROP POLICY IF EXISTS "Usuarios pueden ver mensajes de sus conversaciones" ON public.mensajes_soporte;
CREATE POLICY "Usuarios pueden ver mensajes de sus conversaciones"
ON public.mensajes_soporte
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.conversaciones_soporte
    WHERE conversaciones_soporte.id = mensajes_soporte.conversacion_id
    AND (
      conversaciones_soporte.repartidor_auth_id = auth.uid()
      OR
      EXISTS (
        SELECT 1 FROM public.usuarios
        WHERE usuarios.auth_id = auth.uid()
        AND usuarios.role = 'ADMIN'
      )
    )
  )
);

DROP POLICY IF EXISTS "Usuarios pueden insertar mensajes" ON public.mensajes_soporte;
CREATE POLICY "Usuarios pueden insertar mensajes"
ON public.mensajes_soporte
FOR INSERT
WITH CHECK (
  remitente_auth_id = auth.uid()
);

DROP POLICY IF EXISTS "Usuarios pueden actualizar mensajes" ON public.mensajes_soporte;
CREATE POLICY "Usuarios pueden actualizar mensajes"
ON public.mensajes_soporte
FOR UPDATE
USING (true);

-- 3. Verificar que realtime esté habilitado
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
AND tablename IN ('conversaciones_soporte', 'mensajes_soporte');
