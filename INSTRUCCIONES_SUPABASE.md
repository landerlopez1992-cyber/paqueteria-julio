# 🚀 MIGRACIÓN A SUPABASE - J Alvarez Express SVC

## 📋 Instrucciones Paso a Paso

### 1️⃣ **Configurar Supabase**

**Ya tienes un proyecto creado:**
- Proyecto: `cubcolexpress@gmail.com's Project`
- URL visible en tu pantalla: `supabase.com/dashboard/project/fbbvfzeyh...`

### 2️⃣ **Ejecutar el Script SQL**

1. **En Supabase, ve a:**
   - **SQL Editor** (icono de consola/terminal en el menú lateral)

2. **Crea una nueva query:**
   - Haz clic en **"New query"**
   
3. **Copia todo el contenido del archivo** `supabase_migration.sql`

4. **Pega el SQL** en el editor

5. **Ejecuta** (botón "Run" o Ctrl/Cmd + Enter)

### 3️⃣ **Crear Usuarios en Authentication**

1. **Ve a Authentication → Users**

2. **Crea el usuario Administrador:**
   - Email: `admin@paqueteria.com`
   - Password: `Admin123!`
   - Haz clic en "Create user"

3. **Crea el usuario Repartidor:**
   - Email: `repartidor@paqueteria.com`
   - Password: `Rep123!`
   - Haz clic en "Create user"

4. **Copia los UUIDs:**
   - Después de crear cada usuario, verás su UUID (id)
   - Guarda estos UUIDs

### 4️⃣ **Insertar Perfiles de Usuario**

1. **Ve a SQL Editor** nuevamente

2. **Ejecuta estos INSERT** (reemplaza los UUIDs):

```sql
-- Reemplaza UUID_DEL_ADMIN y UUID_DEL_REPARTIDOR con los UUIDs reales
INSERT INTO usuarios (email, nombre, rol, auth_id) VALUES
('admin@paqueteria.com', 'Administrador Principal', 'ADMINISTRADOR', 'UUID_DEL_ADMIN'),
('repartidor@paqueteria.com', 'Juan Repartidor', 'REPARTIDOR', 'UUID_DEL_REPARTIDOR');
```

### 5️⃣ **Obtener Credenciales de Supabase**

1. **Ve a Settings → API**

2. **Copia estas credenciales:**
   - **Project URL:** `https://xxxxx.supabase.co`
   - **anon public key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. **Envíamelas** para configurar la app Flutter

### 6️⃣ **Verificar Tablas Creadas**

En **Table Editor**, deberías ver:
- ✅ usuarios
- ✅ emisores
- ✅ receptores
- ✅ ordenes
- ✅ historial_estados

## 📊 **Estructura de Datos**

### Tablas Principales:

1. **usuarios**
   - Almacena los perfiles de usuario
   - Roles: ADMINISTRADOR, REPARTIDOR
   - Vinculado con Supabase Auth

2. **emisores**
   - Quienes envían paquetes
   - Datos de contacto y dirección

3. **receptores**
   - Quienes reciben paquetes
   - Datos de contacto y dirección de entrega

4. **ordenes**
   - Órdenes de envío
   - Estados: CREADA, ENVIADA, REPARTIENDO, ENTREGADA, CANCELADA
   - Vinculadas con emisor, receptor, creador y repartidor

5. **historial_estados**
   - Registro de cambios de estado
   - Se llena automáticamente con triggers

## 🔐 **Seguridad (Row Level Security)**

El script incluye políticas de seguridad:
- **ADMINISTRADOR:** Puede crear, editar y eliminar todo
- **REPARTIDOR:** Puede ver todo, pero solo editar órdenes asignadas a él
- **Usuarios:** Solo pueden ver y editar su propio perfil

## 🎯 **Funciones Incluidas**

1. **generar_numero_orden()**: Genera números de orden automáticos (ORD-20251017-0001)
2. **obtener_estadisticas()**: Devuelve estadísticas de órdenes
3. **vista_ordenes_completa**: Vista con toda la información de órdenes

## 📱 **Próximos Pasos**

Después de configurar Supabase:
1. Te ayudo a actualizar la app Flutter con las credenciales de Supabase
2. Probamos el login
3. Probamos crear órdenes

## 💡 **Ventajas de Supabase**

- ✅ Configuración más simple que Firebase
- ✅ PostgreSQL (base de datos relacional robusta)
- ✅ Row Level Security incluido
- ✅ Triggers y funciones nativas
- ✅ Dashboard visual para gestionar datos
- ✅ API REST generada automáticamente
- ✅ Realtime subscriptions

---

**¿Listo para empezar? Sigue los pasos y avísame cuando hayas ejecutado el SQL y creado los usuarios en Authentication.**
