-- Agregar campos de pago a la tabla ordenes

-- 1. Agregar columna para indicar si requiere pago
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS requiere_pago BOOLEAN DEFAULT FALSE;

-- 2. Agregar columna para el monto a cobrar
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS monto_cobrar NUMERIC(10,2) DEFAULT 0.00;

-- 3. Agregar columna para la moneda (USD o CUP)
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS moneda TEXT DEFAULT 'CUP' CHECK (moneda IN ('USD', 'CUP'));

-- 4. Agregar columna para indicar si ya está pagado
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS pagado BOOLEAN DEFAULT FALSE;

-- 5. Agregar columna para la fecha de pago
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS fecha_pago TIMESTAMP WITH TIME ZONE;

-- 6. Agregar columna para notas del pago
ALTER TABLE ordenes ADD COLUMN IF NOT EXISTS notas_pago TEXT;

-- Comentarios para documentación
COMMENT ON COLUMN ordenes.requiere_pago IS 'Indica si la orden requiere pago al momento de la entrega';
COMMENT ON COLUMN ordenes.monto_cobrar IS 'Monto que debe cobrar el repartidor';
COMMENT ON COLUMN ordenes.moneda IS 'Moneda del pago: USD o CUP';
COMMENT ON COLUMN ordenes.pagado IS 'Indica si el cliente ya pagó';
COMMENT ON COLUMN ordenes.fecha_pago IS 'Fecha y hora en que se realizó el pago';
COMMENT ON COLUMN ordenes.notas_pago IS 'Notas adicionales sobre el pago';

-- Verificar las columnas agregadas
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'ordenes' 
AND column_name IN ('requiere_pago', 'monto_cobrar', 'moneda', 'pagado', 'fecha_pago', 'notas_pago')
ORDER BY ordinal_position;

