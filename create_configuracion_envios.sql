-- Tabla para almacenar la configuración de envíos
CREATE TABLE IF NOT EXISTS configuracion_envios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Prioridad de órdenes
    prioridad_urgentes BOOLEAN DEFAULT TRUE,
    ordenar_por_fecha BOOLEAN DEFAULT FALSE,
    ordenar_por_distancia BOOLEAN DEFAULT TRUE,
    
    -- Configuración de impresión
    tipo_impresion TEXT DEFAULT 'etiqueta_completa' CHECK (tipo_impresion IN ('etiqueta_completa', 'codigo_qr', 'manual')),
    incluir_qr BOOLEAN DEFAULT TRUE,
    incluir_datos_destinatario BOOLEAN DEFAULT TRUE,
    incluir_numero_orden BOOLEAN DEFAULT TRUE,
    
    -- Rastreo
    mostrar_rastreo_usuarios BOOLEAN DEFAULT TRUE,
    rastreo_tiempo_real BOOLEAN DEFAULT FALSE,
    intervalo_actualizacion INTEGER DEFAULT 30, -- segundos
    
    -- Notificaciones
    notificaciones_emisores BOOLEAN DEFAULT TRUE,
    notificaciones_destinatarios BOOLEAN DEFAULT FALSE,
    notificaciones_repartidores BOOLEAN DEFAULT TRUE,
    notificaciones_email BOOLEAN DEFAULT TRUE,
    notificaciones_sms BOOLEAN DEFAULT FALSE,
    
    -- Entrega
    confirmacion_entrega BOOLEAN DEFAULT TRUE,
    foto_entrega_obligatoria BOOLEAN DEFAULT TRUE,
    firma_digital BOOLEAN DEFAULT FALSE,
    tiempo_espera_entrega INTEGER DEFAULT 15, -- minutos
    
    -- Geolocalización
    geolocalizacion_obligatoria BOOLEAN DEFAULT TRUE,
    radio_entrega NUMERIC(10,2) DEFAULT 100.0, -- metros
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Comentarios para documentación
COMMENT ON TABLE configuracion_envios IS 'Almacena toda la configuración del módulo de envíos';
COMMENT ON COLUMN configuracion_envios.prioridad_urgentes IS 'Si TRUE, las órdenes urgentes se priorizan automáticamente';
COMMENT ON COLUMN configuracion_envios.tipo_impresion IS 'Tipo de etiqueta que imprime la impresora: etiqueta_completa, codigo_qr, manual';
COMMENT ON COLUMN configuracion_envios.radio_entrega IS 'Radio en metros desde el punto de entrega para marcar como entregado';

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_configuracion_envios_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_configuracion_envios_updated_at
    BEFORE UPDATE ON configuracion_envios
    FOR EACH ROW
    EXECUTE FUNCTION update_configuracion_envios_updated_at();

-- Insertar configuración por defecto (solo si no existe)
INSERT INTO configuracion_envios (id)
VALUES ('00000000-0000-0000-0000-000000000001')
ON CONFLICT (id) DO NOTHING;

-- Política RLS (permitir a todos los usuarios autenticados leer y actualizar)
ALTER TABLE configuracion_envios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir lectura de configuración" ON configuracion_envios;
CREATE POLICY "Permitir lectura de configuración" ON configuracion_envios
    FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Permitir actualización de configuración" ON configuracion_envios;
CREATE POLICY "Permitir actualización de configuración" ON configuracion_envios
    FOR UPDATE
    TO authenticated
    USING (true);

-- Verificar que se creó correctamente
SELECT * FROM configuracion_envios;

