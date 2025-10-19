-- Verificar todos los usuarios y sus roles
SELECT id, nombre, email, rol, created_at 
FROM usuarios 
ORDER BY created_at DESC;

-- Verificar específicamente los repartidores
SELECT id, nombre, email, rol, created_at 
FROM usuarios 
WHERE rol = 'repartidor'
ORDER BY created_at DESC;

-- Contar usuarios por rol
SELECT rol, COUNT(*) as cantidad
FROM usuarios 
GROUP BY rol
ORDER BY cantidad DESC;
