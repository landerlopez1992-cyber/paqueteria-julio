-- Primero, eliminar la tabla si existe (para empezar limpio)
DROP TABLE IF EXISTS public.ordenes CASCADE;

-- Eliminar el tipo enum si existe
DROP TYPE IF EXISTS estado_orden CASCADE;

-- Crear tipo enum para estados de orden
CREATE TYPE estado_orden AS ENUM ('POR ENVIAR', 'EN TRANSITO', 'ENTREGADO', 'CANCELADA');

-- Crear tabla ordenes SIN foreign keys
CREATE TABLE public.ordenes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    emisor_nombre TEXT,
    destinatario_nombre TEXT,
    repartidor_nombre TEXT,
    descripcion TEXT NOT NULL,
    direccion_destino TEXT NOT NULL,
    estado estado_orden DEFAULT 'POR ENVIAR',
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_envio TIMESTAMP WITH TIME ZONE,
    fecha_entrega TIMESTAMP WITH TIME ZONE,
    notas TEXT,
    creado_por_nombre TEXT DEFAULT 'Super-Admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comentarios
COMMENT ON TABLE public.ordenes IS 'Tabla para almacenar órdenes de envío';

-- Crear índices
CREATE INDEX idx_ordenes_estado ON public.ordenes(estado);
CREATE INDEX idx_ordenes_fecha_creacion ON public.ordenes(fecha_creacion);

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_ordenes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER update_ordenes_updated_at_trigger
BEFORE UPDATE ON public.ordenes
FOR EACH ROW EXECUTE FUNCTION update_ordenes_updated_at();

-- Habilitar RLS
ALTER TABLE public.ordenes ENABLE ROW LEVEL SECURITY;

-- Política
CREATE POLICY "Permitir todas las operaciones a usuarios autenticados" ON public.ordenes
    FOR ALL USING (auth.uid() IS NOT NULL);

-- Insertar datos de ejemplo
INSERT INTO public.ordenes (emisor_nombre, destinatario_nombre, descripcion, direccion_destino, estado, fecha_creacion, notas) VALUES
('Juan Pérez', 'María González', 'Paquete de documentos importantes', 'Calle Principal #123, Ciudad', 'EN TRANSITO', NOW() - INTERVAL '2 days', 'Urgente'),
('Carlos Ruiz', 'Ana Martínez', 'Caja con productos electrónicos', 'Avenida Central #456, Ciudad', 'POR ENVIAR', NOW() - INTERVAL '1 day', 'Frágil'),
('Pedro López', 'Laura García', 'Paquete de ropa', 'Calle Norte #789, Ciudad', 'ENTREGADO', NOW() - INTERVAL '5 days', NULL),
('Sofía Herrera', 'Miguel Torres', 'Libros y material educativo', 'Plaza Mayor #321, Ciudad', 'EN TRANSITO', NOW() - INTERVAL '6 hours', NULL),
('Roberto Silva', 'Carmen Díaz', 'Productos de farmacia', 'Avenida Sur #654, Ciudad', 'POR ENVIAR', NOW() - INTERVAL '3 hours', NULL),
('Luis Mendoza', 'Patricia Vega', 'Documentos legales', 'Calle Secundaria #789, Ciudad', 'CANCELADA', NOW() - INTERVAL '3 days', 'Cliente canceló'),
('Elena Castro', 'Fernando Ramos', 'Regalo de cumpleaños', 'Avenida Norte #321, Ciudad', 'ENTREGADO', NOW() - INTERVAL '7 days', NULL);

-- Actualizar algunas órdenes con fecha de entrega
UPDATE public.ordenes 
SET fecha_entrega = fecha_creacion + INTERVAL '4 days'
WHERE estado = 'ENTREGADO';

-- Verificar
SELECT COUNT(*) as total_ordenes FROM public.ordenes;

