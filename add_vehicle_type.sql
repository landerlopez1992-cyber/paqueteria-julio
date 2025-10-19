-- Agregar campo tipo_vehiculo a la tabla usuarios
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS tipo_vehiculo TEXT;

-- Comentario para la columna
COMMENT ON COLUMN public.usuarios.tipo_vehiculo IS 'Tipo de vehículo del repartidor: moto, bicicleta, van, camion, auto';

-- Actualizar usuarios existentes con tipo de vehículo por defecto
UPDATE public.usuarios 
SET tipo_vehiculo = 'moto'
WHERE rol = 'REPARTIDOR' AND tipo_vehiculo IS NULL;
