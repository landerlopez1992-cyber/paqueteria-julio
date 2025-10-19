-- Crear tablas para el sistema de chat de soporte

-- Tabla de conversaciones
CREATE TABLE IF NOT EXISTS public.conversaciones_soporte (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    repartidor_auth_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    estado VARCHAR(20) DEFAULT 'ABIERTA' CHECK (estado IN ('ABIERTA', 'CERRADA')),
    ultimo_mensaje_fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de mensajes
CREATE TABLE IF NOT EXISTS public.mensajes_soporte (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversacion_id UUID NOT NULL REFERENCES public.conversaciones_soporte(id) ON DELETE CASCADE,
    remitente_auth_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_conversaciones_repartidor ON public.conversaciones_soporte(repartidor_auth_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_estado ON public.conversaciones_soporte(estado);
CREATE INDEX IF NOT EXISTS idx_mensajes_conversacion ON public.mensajes_soporte(conversacion_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente ON public.mensajes_soporte(remitente_auth_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_leido ON public.mensajes_soporte(leido);

-- Función para actualizar ultimo_mensaje_fecha automáticamente
CREATE OR REPLACE FUNCTION update_ultimo_mensaje_fecha()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversaciones_soporte 
    SET ultimo_mensaje_fecha = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversacion_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar fecha automáticamente
DROP TRIGGER IF EXISTS trigger_update_ultimo_mensaje ON public.mensajes_soporte;
CREATE TRIGGER trigger_update_ultimo_mensaje
    AFTER INSERT ON public.mensajes_soporte
    FOR EACH ROW
    EXECUTE FUNCTION update_ultimo_mensaje_fecha();

-- Políticas RLS (Row Level Security)
ALTER TABLE public.conversaciones_soporte ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes_soporte ENABLE ROW LEVEL SECURITY;

-- Política para conversaciones: repartidores pueden ver sus propias conversaciones, admins pueden ver todas
DROP POLICY IF EXISTS "Repartidores pueden ver sus conversaciones" ON public.conversaciones_soporte;
CREATE POLICY "Repartidores pueden ver sus conversaciones"
ON public.conversaciones_soporte
FOR ALL
USING (
    repartidor_auth_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM public.usuarios u
        WHERE u.auth_id = auth.uid()
        AND u.rol = 'ADMINISTRADOR'
    )
);

-- Política para mensajes: usuarios pueden ver mensajes de sus conversaciones
DROP POLICY IF EXISTS "Usuarios pueden ver mensajes de sus conversaciones" ON public.mensajes_soporte;
CREATE POLICY "Usuarios pueden ver mensajes de sus conversaciones"
ON public.mensajes_soporte
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM public.conversaciones_soporte c
        WHERE c.id = conversacion_id
        AND (
            c.repartidor_auth_id = auth.uid() OR
            EXISTS (
                SELECT 1 FROM public.usuarios u
                WHERE u.auth_id = auth.uid()
                AND u.rol = 'ADMINISTRADOR'
            )
        )
    )
);

-- Comentarios
COMMENT ON TABLE public.conversaciones_soporte IS 'Conversaciones de chat entre repartidores y administradores';
COMMENT ON TABLE public.mensajes_soporte IS 'Mensajes individuales dentro de las conversaciones de soporte';
COMMENT ON COLUMN public.conversaciones_soporte.estado IS 'Estado de la conversación: ABIERTA o CERRADA';
COMMENT ON COLUMN public.mensajes_soporte.leido IS 'Indica si el mensaje ha sido leído por el destinatario';
