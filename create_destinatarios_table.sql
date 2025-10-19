-- Crear tabla destinatarios
CREATE TABLE IF NOT EXISTS public.destinatarios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nombre TEXT NOT NULL,
    email TEXT,
    telefono TEXT,
    direccion TEXT,
    municipio TEXT,
    provincia TEXT,
    consejo_popular_batey TEXT,
    empresa TEXT,
    notas TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comentarios para las columnas
COMMENT ON TABLE public.destinatarios IS 'Tabla para almacenar información de destinatarios de paquetes';
COMMENT ON COLUMN public.destinatarios.nombre IS 'Nombre completo del destinatario';
COMMENT ON COLUMN public.destinatarios.email IS 'Email de contacto del destinatario';
COMMENT ON COLUMN public.destinatarios.telefono IS 'Teléfono de contacto del destinatario';
COMMENT ON COLUMN public.destinatarios.direccion IS 'Dirección completa del destinatario';
COMMENT ON COLUMN public.destinatarios.municipio IS 'Municipio del destinatario';
COMMENT ON COLUMN public.destinatarios.provincia IS 'Provincia del destinatario';
COMMENT ON COLUMN public.destinatarios.consejo_popular_batey IS 'Consejo Popular o Batey del destinatario';
COMMENT ON COLUMN public.destinatarios.empresa IS 'Empresa del destinatario (opcional)';
COMMENT ON COLUMN public.destinatarios.notas IS 'Notas adicionales sobre el destinatario';

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_destinatarios_nombre ON public.destinatarios(nombre);
CREATE INDEX IF NOT EXISTS idx_destinatarios_email ON public.destinatarios(email);
CREATE INDEX IF NOT EXISTS idx_destinatarios_telefono ON public.destinatarios(telefono);
CREATE INDEX IF NOT EXISTS idx_destinatarios_municipio ON public.destinatarios(municipio);
CREATE INDEX IF NOT EXISTS idx_destinatarios_provincia ON public.destinatarios(provincia);
CREATE INDEX IF NOT EXISTS idx_destinatarios_created_at ON public.destinatarios(created_at);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_destinatarios_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_update_destinatarios_updated_at ON public.destinatarios;
CREATE TRIGGER trigger_update_destinatarios_updated_at
    BEFORE UPDATE ON public.destinatarios
    FOR EACH ROW
    EXECUTE FUNCTION update_destinatarios_updated_at();

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.destinatarios ENABLE ROW LEVEL SECURITY;

-- Política para permitir todas las operaciones a usuarios autenticados
DROP POLICY IF EXISTS "Permitir todas las operaciones a usuarios autenticados" ON public.destinatarios;
CREATE POLICY "Permitir todas las operaciones a usuarios autenticados" ON public.destinatarios
    FOR ALL USING (auth.uid() IS NOT NULL);

-- Insertar algunos destinatarios de ejemplo
INSERT INTO public.destinatarios (nombre, email, telefono, direccion, municipio, provincia, consejo_popular_batey, empresa, notas) VALUES
('María González', 'maria.gonzalez@email.com', '+53 5 123-4567', 'Calle Principal #123', 'Centro Habana', 'La Habana', 'Consejo Popular Cayo Hueso', 'Empresa ABC', 'Destinatario frecuente'),
('Ana Martínez', 'ana.martinez@email.com', '+53 5 234-5678', 'Avenida Central #456', 'Santiago de Cuba', 'Santiago de Cuba', 'Consejo Popular José Martí', 'Comercial XYZ', 'Preferencia: entregas en horario matutino'),
('Laura García', 'laura.garcia@email.com', '+53 5 345-6789', 'Calle Norte #789', 'Camagüey', 'Camagüey', 'Consejo Popular Ignacio Agramonte', NULL, 'Recibe paquetes para toda la familia'),
('Miguel Torres', 'miguel.torres@email.com', '+53 5 456-7890', 'Plaza Mayor #321', 'Holguín', 'Holguín', 'Consejo Popular Pedro Díaz Coello', 'Distribuidora Norte', 'Contactar antes de entregar'),
('Carmen Díaz', 'carmen.diaz@email.com', '+53 5 567-8901', 'Avenida #5A', 'Cienfuegos', 'Cienfuegos', 'Consejo Popular Reina', NULL, 'Horario de recepción: 8:00-17:00');

-- Verificar que la tabla se creó correctamente
SELECT 'Tabla destinatarios creada exitosamente' as resultado;
