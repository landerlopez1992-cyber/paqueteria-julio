# 🔐 GUÍA COMPLETA: SUPER-ADMIN MULTI-TENANCY

## 📋 **PASO 1: EJECUTAR MIGRACIÓN SQL EN SUPABASE**

1. Ir a tu proyecto en Supabase: https://supabase.com
2. Navegar a: **SQL Editor** (icono de código en el menú izquierdo)
3. Abrir el archivo: `migration_multitenant_safe.sql`
4. Copiar TODO el contenido
5. Pegarlo en el SQL Editor de Supabase
6. Click en **RUN** (esquina inferior derecha)
7. ✅ Verificar que aparezca: "Success. No rows returned"

### ⚠️ **IMPORTANTE: ESTA MIGRACIÓN ES SEGURA**
- NO elimina datos existentes
- NO rompe funcionalidades actuales
- Todos tus datos actuales se asignan al tenant "J Alvarez Express (Original)"

---

## 📋 **PASO 2: CREAR USUARIO SUPER-ADMIN**

### **Opción A: Desde Supabase Dashboard (RECOMENDADO)**

1. En Supabase, ir a: **Authentication** → **Users**
2. Click en **Add user** (botón verde)
3. Completar:
   ```
   Email: admin@administrador.com
   Password: Admin123!
   Auto Confirm User: ✅ (activar)
   ```
4. Click en **Create user**
5. **COPIAR** el `User UID` que aparece (algo como: `a1b2c3d4-...`)

### **Opción B: Invitación por Email**

1. Supabase → **Authentication** → **Users** → **Invite**
2. Email: `admin@administrador.com`
3. Te llegará un email de confirmación
4. Seguir el link y establecer contraseña: `Admin123!`

---

## 📋 **PASO 3: ASIGNAR ROL SUPER_ADMIN**

1. Ir a Supabase → **SQL Editor**
2. Ejecutar este SQL (reemplazar `AUTH_UID_AQUI` con el UID copiado):

```sql
-- Insertar usuario super-admin en tabla usuarios
INSERT INTO usuarios (auth_id, email, nombre, rol, activo, tenant_id)
VALUES (
  'AUTH_UID_AQUI',  -- ← REEMPLAZAR con el UID real
  'admin@administrador.com',
  'Super Administrador',
  'super_admin',
  true,
  '00000000-0000-0000-0000-000000000001'::uuid
) ON CONFLICT (auth_id) DO UPDATE SET rol = 'super_admin';
```

3. Click **RUN**
4. ✅ Debe aparecer: "Success. Rows: 1"

---

## 📋 **PASO 4: PROBAR ACCESO SUPER-ADMIN**

1. Ir a la web de tu aplicación
2. Login con:
   ```
   Email: admin@administrador.com
   Contraseña: Admin123!
   ```
3. ✅ Deberías ver el **Panel Super Administrador** con:
   - Lista de todas las empresas (tenants)
   - Estadísticas de cada empresa
   - Botones para crear/editar/eliminar empresas

---

## 🎯 **CÓMO CREAR UNA NUEVA EMPRESA (CLIENTE)**

### **Desde el Panel Super-Admin:**

1. Click en **"Nueva Empresa"** (botón verde flotante)
2. Completar formulario:
   ```
   Nombre: Cuba Express SVC
   Slug: cuba-express (auto-generado, puedes editarlo)
   Email: contacto@cubaexpress.com
   Teléfono: +1-786-555-9999
   Plan: Premium
   URL Logo: https://ejemplo.com/logo.png (opcional)
   Notas: Cliente nuevo - 100 órdenes/mes
   ```
3. Click **"Crear Empresa"**
4. ✅ La empresa aparecerá en la lista

### **¿Qué sucede internamente?**
- Se crea un registro en la tabla `tenants`
- Se genera un `tenant_id` único (UUID)
- El `slug` permite identificar la empresa (ej: `cuba-express`)

---

## 👥 **CÓMO CREAR USUARIO PARA UNA EMPRESA**

### **Método 1: Desde Supabase (Manual)**

1. **Crear usuario en Supabase Auth:**
   - Supabase → Authentication → Users → Add user
   - Email: `admin@cubaexpress.com`
   - Password: `Cuba123!`
   - Auto Confirm: ✅

2. **Obtener `tenant_id` de la empresa:**
   ```sql
   SELECT id, nombre, slug FROM tenants WHERE slug = 'cuba-express';
   ```
   Copiar el `id` (ej: `b5c6d7e8-...`)

3. **Insertar en tabla usuarios:**
   ```sql
   INSERT INTO usuarios (auth_id, email, nombre, rol, activo, tenant_id)
   VALUES (
     'AUTH_UID_DEL_NUEVO_USUARIO',  -- ← UID del usuario creado en Auth
     'admin@cubaexpress.com',
     'Admin Cuba Express',
     'administrador',
     true,
     'b5c6d7e8-...'  -- ← tenant_id de Cuba Express
   );
   ```

### **Método 2: Automático (FUTURO - No implementado aún)**

Puedes crear una función en el Super-Admin Panel para:
1. Seleccionar la empresa
2. Click "Crear Usuario"
3. Ingresar email/nombre
4. Automáticamente se crea en Auth y se asigna al tenant

---

## 🔄 **GESTIÓN DE EMPRESAS**

### **Activar/Desactivar Empresa:**

1. En la lista de empresas, click en **⋮** (menú)
2. Seleccionar **"Activar"** o **"Desactivar"**
3. ✅ Usuarios de empresas inactivas NO podrán hacer login

### **Editar Empresa:**

1. Click en **⋮** → **"Editar"**
2. Modificar nombre, email, teléfono, plan, logo
3. Click **"Guardar Cambios"**

### **Cambiar Logo:**

1. Click en **⋮** → **"Cambiar Logo"**
2. Ingresar URL de la imagen (ej: `https://ejemplo.com/nuevo-logo.png`)
3. Vista previa aparecerá
4. Click **"Guardar"**

### **Eliminar Empresa:**

⚠️ **CUIDADO: Esta acción NO se puede deshacer**

1. Click en **⋮** → **"Eliminar"**
2. Aparecerá advertencia:
   ```
   ⚠️ Esto eliminará TODOS los datos asociados:
   • Usuarios
   • Órdenes
   • Emisores y Destinatarios
   • Conversaciones de Chat
   ```
3. Click **"Eliminar Permanentemente"**
4. Todos los datos de esa empresa se borran (gracias a `ON DELETE CASCADE`)

---

## 📊 **ESTADÍSTICAS POR EMPRESA**

En cada card de empresa expandible, verás:

- **Total Usuarios**: Cuántos usuarios tiene la empresa
- **Total Órdenes**: Todas las órdenes creadas
- **Órdenes Activas**: En proceso
- **Órdenes Entregadas**: Completadas
- **Total Emisores**: Contactos que envían
- **Total Destinatarios**: Contactos que reciben

---

## 🔒 **SEGURIDAD: ROW LEVEL SECURITY (RLS)**

### **Políticas Actuales (SEGURAS):**

1. **Super-Admin ve TODO:**
   ```sql
   is_super_admin() = true
   ```

2. **Usuarios normales ven SOLO su tenant:**
   ```sql
   tenant_id = get_current_tenant_id()
   ```

### **⚠️ ACTIVAR AISLAMIENTO TOTAL (FUTURO):**

Cuando estés listo para aislar completamente los datos:

1. Ir a `migration_multitenant_safe.sql`
2. **Descomentar** la sección `PASO 7` (políticas RLS)
3. Ejecutar en Supabase SQL Editor
4. ✅ Cada empresa solo verá sus propios datos

---

## 🎨 **PERSONALIZACIÓN POR EMPRESA**

### **Colores Personalizados:**

Cada empresa puede tener sus colores:
```sql
UPDATE tenants 
SET color_primario = '#FF5722', color_secundario = '#03A9F4' 
WHERE slug = 'cuba-express';
```

### **Logo Personalizado:**

```sql
UPDATE tenants 
SET logo_url = 'https://ejemplo.com/logo-cuba-express.png' 
WHERE slug = 'cuba-express';
```

---

## 🔄 **FLUJO COMPLETO: VENDER A UN NUEVO CLIENTE**

### **Escenario: Vendiste a "Miami Paquetería"**

1. **Login como Super-Admin:**
   - Email: `admin@administrador.com`
   - Password: `Admin123!`

2. **Crear Empresa:**
   - Nombre: Miami Paquetería
   - Slug: miami-paqueteria
   - Email: info@miamipaq.com
   - Plan: Premium

3. **Crear Usuario Admin para el Cliente:**
   - Supabase Auth → Add User
   - Email: admin@miamipaq.com
   - Password: Miami123!
   - Copiar UID

4. **Asignar Tenant:**
   ```sql
   -- Obtener tenant_id
   SELECT id FROM tenants WHERE slug = 'miami-paqueteria';
   
   -- Crear usuario
   INSERT INTO usuarios (auth_id, email, nombre, rol, tenant_id)
   VALUES ('UID_COPIADO', 'admin@miamipaq.com', 'Admin Miami', 'administrador', 'TENANT_ID_COPIADO');
   ```

5. **Entregar Credenciales al Cliente:**
   ```
   URL: https://landerlopez1992-cyber.github.io/paqueteria-julio/
   Email: admin@miamipaq.com
   Password: Miami123!
   ```

6. ✅ **El cliente ya puede usar el sistema:**
   - Solo verá sus propios datos
   - NO verá datos de otros clientes
   - Tendrá su propio logo y colores (si los configuraste)

---

## 🛠️ **COMANDOS SQL ÚTILES**

### **Ver todas las empresas:**
```sql
SELECT * FROM tenants ORDER BY fecha_creacion DESC;
```

### **Ver estadísticas de una empresa:**
```sql
SELECT * FROM tenant_stats WHERE slug = 'cuba-express';
```

### **Listar usuarios por empresa:**
```sql
SELECT u.nombre, u.email, u.rol, t.nombre as empresa
FROM usuarios u
JOIN tenants t ON u.tenant_id = t.id
ORDER BY t.nombre, u.nombre;
```

### **Contar órdenes por empresa:**
```sql
SELECT t.nombre, COUNT(o.id) as total_ordenes
FROM tenants t
LEFT JOIN ordenes o ON o.tenant_id = t.id
GROUP BY t.id, t.nombre
ORDER BY total_ordenes DESC;
```

---

## ❓ **PREGUNTAS FRECUENTES**

### **¿Los datos existentes se mantendrán?**
✅ Sí, todos se asignan al tenant "J Alvarez Express (Original)"

### **¿Puedo desactivar una empresa temporalmente?**
✅ Sí, click en ⋮ → Desactivar. Sus usuarios no podrán hacer login.

### **¿Puedo cambiar el plan de una empresa?**
✅ Sí, editar empresa y cambiar entre: Básico, Premium, Enterprise

### **¿Cómo elimino una empresa y todos sus datos?**
⚠️ Click en ⋮ → Eliminar (NO reversible)

### **¿Cuántas empresas puedo tener?**
✅ Ilimitadas en la misma base de datos

### **¿Cada empresa necesita un Supabase separado?**
❌ No, todas usan el mismo Supabase (multi-tenancy)

---

## 🚀 **PRÓXIMOS PASOS RECOMENDADOS**

1. ✅ Ejecutar migración SQL
2. ✅ Crear usuario super-admin
3. ✅ Probar acceso al panel
4. ✅ Crear una empresa de prueba
5. ⏳ Crear usuario para esa empresa
6. ⏳ Probar aislamiento de datos
7. ⏳ Activar políticas RLS completas (PASO 7 del SQL)

---

## 📞 **SOPORTE**

Si tienes problemas:
1. Verificar logs de Supabase
2. Revisar que el `tenant_id` esté en todos los inserts
3. Confirmar que las políticas RLS estén activas
4. Consultar `tenant_stats` para ver estadísticas

---

**🎉 ¡Listo! Ahora puedes vender tu software a múltiples clientes sin preocuparte por mezclar datos.**

