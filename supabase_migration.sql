-- =====================================================
-- MIGRACIÓN COMPLETA A SUPABASE
-- J Alvarez Express SVC - Sistema de Paquetería
-- =====================================================

-- =====================================================
-- 1. TABLA DE USUARIOS (con roles)
-- =====================================================
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    rol VARCHAR(50) NOT NULL CHECK (rol IN ('ADMINISTRADOR', 'REPARTIDOR')),
    auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para usuarios
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_usuarios_auth_id ON usuarios(auth_id);

-- =====================================================
-- 2. TABLA DE EMISORES
-- =====================================================
CREATE TABLE emisores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(255) NOT NULL,
    telefono VARCHAR(50),
    direccion TEXT,
    email VARCHAR(255),
    notas TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para emisores
CREATE INDEX idx_emisores_nombre ON emisores(nombre);
CREATE INDEX idx_emisores_email ON emisores(email);

-- =====================================================
-- 3. TABLA DE RECEPTORES
-- =====================================================
CREATE TABLE receptores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(255) NOT NULL,
    telefono VARCHAR(50),
    direccion TEXT NOT NULL,
    email VARCHAR(255),
    ciudad VARCHAR(100),
    codigo_postal VARCHAR(20),
    notas TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para receptores
CREATE INDEX idx_receptores_nombre ON receptores(nombre);
CREATE INDEX idx_receptores_ciudad ON receptores(ciudad);
CREATE INDEX idx_receptores_email ON receptores(email);

-- =====================================================
-- 4. TABLA DE ÓRDENES
-- =====================================================
CREATE TABLE ordenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_orden VARCHAR(50) UNIQUE NOT NULL,
    emisor_id UUID REFERENCES emisores(id) ON DELETE RESTRICT,
    receptor_id UUID REFERENCES receptores(id) ON DELETE RESTRICT,
    direccion_destino TEXT NOT NULL,
    descripcion TEXT,
    notas_adicionales TEXT,
    estado VARCHAR(50) NOT NULL DEFAULT 'CREADA' CHECK (estado IN ('CREADA', 'ENVIADA', 'REPARTIENDO', 'ENTREGADA', 'CANCELADA')),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_envio TIMESTAMP WITH TIME ZONE,
    fecha_estimada_entrega DATE,
    fecha_entrega TIMESTAMP WITH TIME ZONE,
    creada_por UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    repartidor_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para órdenes
CREATE INDEX idx_ordenes_numero ON ordenes(numero_orden);
CREATE INDEX idx_ordenes_estado ON ordenes(estado);
CREATE INDEX idx_ordenes_emisor ON ordenes(emisor_id);
CREATE INDEX idx_ordenes_receptor ON ordenes(receptor_id);
CREATE INDEX idx_ordenes_repartidor ON ordenes(repartidor_id);
CREATE INDEX idx_ordenes_creada_por ON ordenes(creada_por);
CREATE INDEX idx_ordenes_fecha_creacion ON ordenes(fecha_creacion DESC);

-- =====================================================
-- 5. TABLA DE HISTORIAL DE ESTADOS
-- =====================================================
CREATE TABLE historial_estados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_id UUID REFERENCES ordenes(id) ON DELETE CASCADE,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50) NOT NULL,
    notas TEXT,
    cambiado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para historial
CREATE INDEX idx_historial_orden ON historial_estados(orden_id);
CREATE INDEX idx_historial_fecha ON historial_estados(created_at DESC);

-- =====================================================
-- 6. TRIGGERS PARA ACTUALIZAR updated_at
-- =====================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para usuarios
CREATE TRIGGER update_usuarios_updated_at
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para emisores
CREATE TRIGGER update_emisores_updated_at
    BEFORE UPDATE ON emisores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para receptores
CREATE TRIGGER update_receptores_updated_at
    BEFORE UPDATE ON receptores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para órdenes
CREATE TRIGGER update_ordenes_updated_at
    BEFORE UPDATE ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 7. TRIGGER PARA REGISTRAR CAMBIOS DE ESTADO
-- =====================================================

CREATE OR REPLACE FUNCTION log_estado_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        INSERT INTO historial_estados (orden_id, estado_anterior, estado_nuevo)
        VALUES (NEW.id, OLD.estado, NEW.estado);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_orden_estado_changes
    AFTER UPDATE ON ordenes
    FOR EACH ROW
    EXECUTE FUNCTION log_estado_change();

-- =====================================================
-- 8. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE emisores ENABLE ROW LEVEL SECURITY;
ALTER TABLE receptores ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordenes ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_estados ENABLE ROW LEVEL SECURITY;

-- Políticas para usuarios (todos pueden leer, solo ellos mismos pueden actualizar)
CREATE POLICY "Usuarios pueden ver todos los usuarios"
    ON usuarios FOR SELECT
    USING (true);

CREATE POLICY "Usuarios pueden actualizar su propio perfil"
    ON usuarios FOR UPDATE
    USING (auth.uid() = auth_id);

-- Políticas para emisores (ADMINISTRADOR puede todo, REPARTIDOR solo leer)
CREATE POLICY "Todos pueden ver emisores"
    ON emisores FOR SELECT
    USING (true);

CREATE POLICY "Solo ADMINISTRADOR puede crear emisores"
    ON emisores FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

CREATE POLICY "Solo ADMINISTRADOR puede actualizar emisores"
    ON emisores FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

CREATE POLICY "Solo ADMINISTRADOR puede eliminar emisores"
    ON emisores FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

-- Políticas para receptores (similares a emisores)
CREATE POLICY "Todos pueden ver receptores"
    ON receptores FOR SELECT
    USING (true);

CREATE POLICY "Solo ADMINISTRADOR puede crear receptores"
    ON receptores FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

CREATE POLICY "Solo ADMINISTRADOR puede actualizar receptores"
    ON receptores FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

CREATE POLICY "Solo ADMINISTRADOR puede eliminar receptores"
    ON receptores FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

-- Políticas para órdenes
CREATE POLICY "Todos pueden ver órdenes"
    ON ordenes FOR SELECT
    USING (true);

CREATE POLICY "Solo ADMINISTRADOR puede crear órdenes"
    ON ordenes FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

CREATE POLICY "ADMINISTRADOR y REPARTIDOR asignado pueden actualizar órdenes"
    ON ordenes FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND (
                rol = 'ADMINISTRADOR' OR 
                (rol = 'REPARTIDOR' AND id = ordenes.repartidor_id)
            )
        )
    );

CREATE POLICY "Solo ADMINISTRADOR puede eliminar órdenes"
    ON ordenes FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_id = auth.uid() AND rol = 'ADMINISTRADOR'
        )
    );

-- Políticas para historial
CREATE POLICY "Todos pueden ver historial"
    ON historial_estados FOR SELECT
    USING (true);

-- =====================================================
-- 9. DATOS DE PRUEBA
-- =====================================================

-- NOTA: Los usuarios se crearán desde Supabase Auth UI
-- Después de crear usuarios en Auth, ejecutar estos INSERT con los UUIDs correctos

-- Ejemplo de cómo insertar usuarios después de crearlos en Auth:
-- INSERT INTO usuarios (email, nombre, rol, auth_id) VALUES
-- ('admin@paqueteria.com', 'Administrador Principal', 'ADMINISTRADOR', 'UUID_DEL_AUTH'),
-- ('repartidor@paqueteria.com', 'Juan Repartidor', 'REPARTIDOR', 'UUID_DEL_AUTH');

-- Emisores de prueba
INSERT INTO emisores (nombre, telefono, direccion, email) VALUES
('Juan Pérez', '555-1234', 'Calle Principal #123, Ciudad', 'juan.perez@example.com'),
('María García', '555-5678', 'Av. Central #456, Ciudad', 'maria.garcia@example.com'),
('Empresa ABC', '555-9012', 'Zona Industrial #789, Ciudad', 'contacto@empresaabc.com');

-- Receptores de prueba
INSERT INTO receptores (nombre, telefono, direccion, email, ciudad, codigo_postal) VALUES
('Carlos López', '555-2345', 'Calle Norte #234, Barrio Centro', 'carlos.lopez@example.com', 'Ciudad Principal', '12345'),
('Ana Martínez', '555-6789', 'Av. Sur #567, Barrio Oeste', 'ana.martinez@example.com', 'Ciudad Principal', '12346'),
('Tienda XYZ', '555-0123', 'Plaza Comercial #890, Centro', 'info@tiendaxyz.com', 'Ciudad Principal', '12347');

-- =====================================================
-- 10. FUNCIONES ÚTILES
-- =====================================================

-- Función para generar número de orden automático
CREATE OR REPLACE FUNCTION generar_numero_orden()
RETURNS VARCHAR AS $$
DECLARE
    nuevo_numero VARCHAR;
    contador INT;
BEGIN
    -- Obtener el último número del día
    SELECT COUNT(*) + 1 INTO contador
    FROM ordenes
    WHERE DATE(fecha_creacion) = CURRENT_DATE;
    
    -- Generar número: ORD-YYYYMMDD-XXXX
    nuevo_numero := 'ORD-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(contador::TEXT, 4, '0');
    
    RETURN nuevo_numero;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener estadísticas
CREATE OR REPLACE FUNCTION obtener_estadisticas()
RETURNS TABLE (
    total_ordenes BIGINT,
    ordenes_activas BIGINT,
    ordenes_entregadas BIGINT,
    ordenes_hoy BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) AS total_ordenes,
        COUNT(*) FILTER (WHERE estado IN ('CREADA', 'ENVIADA', 'REPARTIENDO')) AS ordenes_activas,
        COUNT(*) FILTER (WHERE estado = 'ENTREGADA') AS ordenes_entregadas,
        COUNT(*) FILTER (WHERE DATE(fecha_creacion) = CURRENT_DATE) AS ordenes_hoy
    FROM ordenes;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 11. VISTAS ÚTILES
-- =====================================================

-- Vista de órdenes con información completa
CREATE OR REPLACE VIEW vista_ordenes_completa AS
SELECT 
    o.id,
    o.numero_orden,
    o.estado,
    o.descripcion,
    o.notas_adicionales,
    o.fecha_creacion,
    o.fecha_envio,
    o.fecha_estimada_entrega,
    o.fecha_entrega,
    e.nombre AS emisor_nombre,
    e.telefono AS emisor_telefono,
    e.email AS emisor_email,
    r.nombre AS receptor_nombre,
    r.telefono AS receptor_telefono,
    r.direccion AS receptor_direccion,
    r.ciudad AS receptor_ciudad,
    u_creador.nombre AS creada_por_nombre,
    u_repartidor.nombre AS repartidor_nombre
FROM ordenes o
LEFT JOIN emisores e ON o.emisor_id = e.id
LEFT JOIN receptores r ON o.receptor_id = r.id
LEFT JOIN usuarios u_creador ON o.creada_por = u_creador.id
LEFT JOIN usuarios u_repartidor ON o.repartidor_id = u_repartidor.id;

-- =====================================================
-- FIN DE LA MIGRACIÓN
-- =====================================================

-- Para ejecutar este script en Supabase:
-- 1. Ve a tu proyecto en Supabase
-- 2. SQL Editor
-- 3. Copia y pega todo este script
-- 4. Ejecuta
--
-- Después de ejecutar:
-- 1. Crea usuarios en Authentication (admin@paqueteria.com, repartidor@paqueteria.com)
-- 2. Inserta los registros en la tabla usuarios con los auth_id correspondientes
-- 3. La app Flutter estará lista para conectarse
