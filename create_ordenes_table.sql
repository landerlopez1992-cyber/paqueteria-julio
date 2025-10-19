-- Crear tipo enum para estados de orden
CREATE TYPE estado_orden AS ENUM ('POR ENVIAR', 'EN TRANSITO', 'ENTREGADO', 'CANCELADA');

-- Crear tabla ordenes
CREATE TABLE IF NOT EXISTS public.ordenes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    emisor_id UUID,
    destinatario_id UUID,
    repartidor_id UUID,
    descripcion TEXT NOT NULL,
    direccion_destino TEXT NOT NULL,
    estado estado_orden DEFAULT 'POR ENVIAR',
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_envio TIMESTAMP WITH TIME ZONE,
    fecha_entrega TIMESTAMP WITH TIME ZONE,
    notas TEXT,
    creado_por UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comentarios para las columnas
COMMENT ON TABLE public.ordenes IS 'Tabla para almacenar órdenes de envío';
COMMENT ON COLUMN public.ordenes.emisor_id IS 'ID del emisor del paquete';
COMMENT ON COLUMN public.ordenes.destinatario_id IS 'ID del destinatario del paquete';
COMMENT ON COLUMN public.ordenes.repartidor_id IS 'ID del repartidor asignado';
COMMENT ON COLUMN public.ordenes.descripcion IS 'Descripción del contenido del paquete';
COMMENT ON COLUMN public.ordenes.direccion_destino IS 'Dirección de destino';
COMMENT ON COLUMN public.ordenes.estado IS 'Estado actual de la orden';
COMMENT ON COLUMN public.ordenes.fecha_creacion IS 'Fecha de creación de la orden';
COMMENT ON COLUMN public.ordenes.fecha_envio IS 'Fecha de envío del paquete';
COMMENT ON COLUMN public.ordenes.fecha_entrega IS 'Fecha de entrega del paquete';
COMMENT ON COLUMN public.ordenes.notas IS 'Notas adicionales sobre la orden';
COMMENT ON COLUMN public.ordenes.creado_por IS 'Usuario que creó la orden';

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_ordenes_emisor ON public.ordenes(emisor_id);
CREATE INDEX IF NOT EXISTS idx_ordenes_destinatario ON public.ordenes(destinatario_id);
CREATE INDEX IF NOT EXISTS idx_ordenes_repartidor ON public.ordenes(repartidor_id);
CREATE INDEX IF NOT EXISTS idx_ordenes_estado ON public.ordenes(estado);
CREATE INDEX IF NOT EXISTS idx_ordenes_fecha_creacion ON public.ordenes(fecha_creacion);
CREATE INDEX IF NOT EXISTS idx_ordenes_creado_por ON public.ordenes(creado_por);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_ordenes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para la función de actualización
DROP TRIGGER IF EXISTS update_ordenes_updated_at_trigger ON public.ordenes;
CREATE TRIGGER update_ordenes_updated_at_trigger
BEFORE UPDATE ON public.ordenes
FOR EACH ROW EXECUTE FUNCTION update_ordenes_updated_at();

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.ordenes ENABLE ROW LEVEL SECURITY;

-- Política para permitir todas las operaciones a usuarios autenticados
DROP POLICY IF EXISTS "Permitir todas las operaciones a usuarios autenticados" ON public.ordenes;
CREATE POLICY "Permitir todas las operaciones a usuarios autenticados" ON public.ordenes
    FOR ALL USING (auth.uid() IS NOT NULL);

-- Insertar algunas órdenes de ejemplo
INSERT INTO public.ordenes (descripcion, direccion_destino, estado, fecha_creacion, notas) VALUES
('Paquete de documentos importantes', 'Calle Principal #123, Ciudad', 'EN TRANSITO', NOW() - INTERVAL '2 days', 'Urgente'),
('Caja con productos electrónicos', 'Avenida Central #456, Ciudad', 'POR ENVIAR', NOW() - INTERVAL '1 day', 'Frágil'),
('Paquete de ropa', 'Calle Norte #789, Ciudad', 'ENTREGADO', NOW() - INTERVAL '5 days', NULL),
('Libros y material educativo', 'Plaza Mayor #321, Ciudad', 'EN TRANSITO', NOW() - INTERVAL '6 hours', NULL),
('Productos de farmacia', 'Avenida Sur #654, Ciudad', 'POR ENVIAR', NOW() - INTERVAL '3 hours', NULL),
('Documentos legales', 'Calle Secundaria #789, Ciudad', 'CANCELADA', NOW() - INTERVAL '3 days', 'Cliente canceló'),
('Regalo de cumpleaños', 'Avenida Norte #321, Ciudad', 'ENTREGADO', NOW() - INTERVAL '7 days', NULL);

-- Verificar que la tabla se creó correctamente
SELECT 'Tabla ordenes creada exitosamente' as resultado;

