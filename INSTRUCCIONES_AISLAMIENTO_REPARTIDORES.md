# 🔒 INSTRUCCIONES: Aislamiento de Repartidores por Empresa

## 📋 RESUMEN

Ahora cada empresa tendrá sus **propios repartidores privados**. Los repartidores creados por una empresa solo serán visibles para esa empresa.

---

## 🚀 PASO 1: Ejecutar SQL en Supabase

1. **Ve a Supabase → SQL Editor**

2. **Copia y pega el contenido del archivo:** `agregar_tenant_id_usuarios.sql`

3. **Ejecuta el SQL** (botón RUN)

4. **Verifica el resultado:**
   - Deberías ver una tabla con todos los usuarios y su empresa asignada
   - Todos los usuarios existentes deberían tener `tenant_id` asignado
   - La verificación mostrará:
     - Total usuarios
     - Usuarios con tenant_id
     - Usuarios sin tenant_id (debería ser 0)

---

## ✅ PASO 2: Verificar en la App

Después de ejecutar el SQL, la app Flutter ya está actualizada con los cambios:

### Lo que hace ahora:

1. **Al cargar repartidores:**
   - El admin obtiene su `tenant_id` automáticamente
   - Solo ve repartidores de SU empresa
   - No ve repartidores de otras empresas

2. **Al crear un repartidor:**
   - Se asigna automáticamente el `tenant_id` del admin
   - El repartidor queda vinculado a esa empresa
   - Solo esa empresa podrá verlo

### Logs que verás en consola:

```
🏢 Tenant ID del admin actual: [UUID]
📊 Cargando repartidores para tenant_id: [UUID]
✅ Repartidores cargados: [número]
```

Al crear un repartidor:
```
👤 Creando repartidor para tenant_id: [UUID]
✅ Repartidor creado exitosamente para esta empresa
```

---

## 🧪 CÓMO PROBAR

### Test 1: Verificar aislamiento
1. Login con `admin@paqueteria.com` (Empresa 1)
2. Ve a "Repartidores"
3. Crea un repartidor: `repartidor1@empresa1.com`
4. Cierra sesión
5. Login con otro admin de otra empresa (si tienes)
6. Ve a "Repartidores"
7. **Resultado esperado:** NO deberías ver `repartidor1@empresa1.com`

### Test 2: Crear repartidor
1. Login como admin de empresa
2. Ve a "Repartidores"
3. Crea nuevo repartidor
4. Mira los logs en consola (F12 → Console)
5. **Resultado esperado:** 
   - Mensaje: `👤 Creando repartidor para tenant_id: ...`
   - Mensaje: `✅ Repartidor creado exitosamente para esta empresa`
   - El repartidor aparece en la lista

### Test 3: Solo ver propios repartidores
1. Login como admin
2. Ve a "Repartidores"
3. Mira los logs: `📊 Cargando repartidores para tenant_id: [UUID]`
4. **Resultado esperado:** Solo ves repartidores de TU empresa

---

## 🔍 VERIFICACIÓN EN SUPABASE

Puedes verificar en Supabase → Table Editor → `usuarios`:

```sql
SELECT 
  u.nombre,
  u.email,
  u.rol,
  t.nombre as empresa
FROM usuarios u
LEFT JOIN tenants t ON u.tenant_id = t.id
WHERE u.rol = 'REPARTIDOR'
ORDER BY t.nombre, u.nombre;
```

Esto te mostrará todos los repartidores agrupados por empresa.

---

## 📝 CAMBIOS REALIZADOS

### Código Flutter (`repartidores_screen.dart`):

1. **Variable agregada:**
   ```dart
   String? _currentTenantId; // Tenant ID del admin actual
   ```

2. **Nueva función:**
   ```dart
   _loadCurrentTenantId() // Obtiene tenant_id del admin logueado
   ```

3. **Filtro agregado en `_loadRepartidores()`:**
   ```dart
   .eq('tenant_id', _currentTenantId!) // FILTRAR POR TENANT
   ```

4. **Asignación en `_createRepartidor()`:**
   ```dart
   'tenant_id': _currentTenantId, // ASIGNAR TENANT_ID
   ```

### SQL (`agregar_tenant_id_usuarios.sql`):

1. Agrega columna `tenant_id` a tabla `usuarios`
2. Asigna tenant por defecto a usuarios existentes
3. Crea índice para performance
4. Queries de verificación

---

## ⚠️ IMPORTANTE

- **EJECUTA EL SQL ANTES** de usar la app actualizada
- Los repartidores existentes se asignarán a la primera empresa
- Si tienes múltiples empresas, puedes reasignar repartidores manualmente en Supabase si es necesario

---

## 🎯 PRÓXIMOS PASOS

Después de verificar que funciona correctamente con repartidores, aplicaremos el mismo filtro a:
- ✅ Emisores (ya deberían tener tenant_id)
- ✅ Destinatarios (ya deberían tener tenant_id)
- ✅ Órdenes (ya deberían tener tenant_id)
- ✅ Conversaciones de chat
- ✅ Configuración de envíos

---

**Fecha:** 21 de Octubre, 2025  
**Estado:** ✅ Listo para probar

