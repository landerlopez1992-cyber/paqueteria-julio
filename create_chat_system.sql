-- ============================================
-- SISTEMA DE CHAT DE SOPORTE
-- ============================================

-- Tabla de conversaciones de chat
CREATE TABLE IF NOT EXISTS public.conversaciones_soporte (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  repartidor_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  estado TEXT NOT NULL DEFAULT 'ABIERTA', -- ABIERTA, CERRADA
  ultimo_mensaje_fecha TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tabla de mensajes de chat
CREATE TABLE IF NOT EXISTS public.mensajes_soporte (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversacion_id UUID NOT NULL REFERENCES public.conversaciones_soporte(id) ON DELETE CASCADE,
  remitente_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  mensaje TEXT NOT NULL,
  leido BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_conversaciones_repartidor ON public.conversaciones_soporte(repartidor_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_estado ON public.conversaciones_soporte(estado);
CREATE INDEX IF NOT EXISTS idx_mensajes_conversacion ON public.mensajes_soporte(conversacion_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_leido ON public.mensajes_soporte(leido);

-- Función para actualizar la fecha del último mensaje
CREATE OR REPLACE FUNCTION actualizar_ultimo_mensaje()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversaciones_soporte
  SET 
    ultimo_mensaje_fecha = NEW.created_at,
    updated_at = NEW.created_at
  WHERE id = NEW.conversacion_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar automáticamente la fecha del último mensaje
DROP TRIGGER IF EXISTS trigger_actualizar_ultimo_mensaje ON public.mensajes_soporte;
CREATE TRIGGER trigger_actualizar_ultimo_mensaje
  AFTER INSERT ON public.mensajes_soporte
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_ultimo_mensaje();

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.conversaciones_soporte ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes_soporte ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para conversaciones
DROP POLICY IF EXISTS "Repartidores pueden ver sus conversaciones" ON public.conversaciones_soporte;
CREATE POLICY "Repartidores pueden ver sus conversaciones"
  ON public.conversaciones_soporte
  FOR SELECT
  USING (
    auth.uid() = repartidor_id OR
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol = 'ADMINISTRADOR'
    )
  );

DROP POLICY IF EXISTS "Repartidores pueden crear conversaciones" ON public.conversaciones_soporte;
CREATE POLICY "Repartidores pueden crear conversaciones"
  ON public.conversaciones_soporte
  FOR INSERT
  WITH CHECK (auth.uid() = repartidor_id);

DROP POLICY IF EXISTS "Administradores pueden actualizar conversaciones" ON public.conversaciones_soporte;
CREATE POLICY "Administradores pueden actualizar conversaciones"
  ON public.conversaciones_soporte
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.usuarios
      WHERE id = auth.uid() AND rol = 'ADMINISTRADOR'
    )
  );

-- Políticas de seguridad para mensajes
DROP POLICY IF EXISTS "Usuarios pueden ver mensajes de sus conversaciones" ON public.mensajes_soporte;
CREATE POLICY "Usuarios pueden ver mensajes de sus conversaciones"
  ON public.mensajes_soporte
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversaciones_soporte
      WHERE id = conversacion_id 
      AND (
        repartidor_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.usuarios
          WHERE usuarios.id = auth.uid() AND usuarios.rol = 'ADMINISTRADOR'
        )
      )
    )
  );

DROP POLICY IF EXISTS "Usuarios pueden enviar mensajes a sus conversaciones" ON public.mensajes_soporte;
CREATE POLICY "Usuarios pueden enviar mensajes a sus conversaciones"
  ON public.mensajes_soporte
  FOR INSERT
  WITH CHECK (
    auth.uid() = remitente_id AND
    EXISTS (
      SELECT 1 FROM public.conversaciones_soporte
      WHERE id = conversacion_id 
      AND (
        repartidor_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.usuarios
          WHERE usuarios.id = auth.uid() AND usuarios.rol = 'ADMINISTRADOR'
        )
      )
    )
  );

DROP POLICY IF EXISTS "Usuarios pueden marcar mensajes como leídos" ON public.mensajes_soporte;
CREATE POLICY "Usuarios pueden marcar mensajes como leídos"
  ON public.mensajes_soporte
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.conversaciones_soporte
      WHERE id = conversacion_id 
      AND (
        repartidor_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.usuarios
          WHERE usuarios.id = auth.uid() AND usuarios.rol = 'ADMINISTRADOR'
        )
      )
    )
  );

-- Comentarios para documentación
COMMENT ON TABLE public.conversaciones_soporte IS 'Conversaciones de chat entre repartidores y administradores';
COMMENT ON TABLE public.mensajes_soporte IS 'Mensajes individuales dentro de conversaciones de soporte';

