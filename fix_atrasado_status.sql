-- Verificar si el estado ATRASADO ya existe
DO $$
BEGIN
    -- Intentar agregar el valor ATRASADO al enum
    BEGIN
        ALTER TYPE estado_orden ADD VALUE 'ATRASADO';
        RAISE NOTICE 'Estado ATRASADO agregado exitosamente';
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Estado ATRASADO ya existe';
    END;
END $$;

-- Verificar todos los valores del enum
SELECT unnest(enum_range(NULL::estado_orden)) as estado ORDER BY estado;


