# 🔐 ESTRUCTURA DE USUARIOS - J ALVAREZ EXPRESS SVC

## 📊 JERARQUÍA DE USUARIOS

### 🔴 SUPER-ADMIN (SOLO TÚ - DUEÑO)
**Email:** `admin@administrador.com`  
**Password:** `Admin123!`  
**Acceso:** Solo Web  
**Panel:** Super-Admin Dashboard

**Funciones:**
- ✅ Ver TODAS las empresas (tenants)
- ✅ Crear nuevas empresas (clientes)
- ✅ Activar/Desactivar empresas
- ✅ Editar datos de empresas
- ✅ Cambiar logos de empresas
- ✅ Ver estadísticas de TODAS las empresas
- ✅ Administrar usuarios de TODAS las empresas
- ✅ Resetear contraseñas
- ✅ Eliminar usuarios
- ✅ Eliminar empresas completas

---

### 🟢 ADMINISTRADOR DE EMPRESA (CLIENTES)
**Ejemplos:**
- `admin@paqueteria.com` (Empresa: J Alvarez Express SVC)
- Cualquier otro email que crees desde el Super-Admin

**Acceso:** Solo Web  
**Panel:** Panel de Administración de Empresa

**Funciones:**
- ✅ Gestionar órdenes de SU empresa
- ✅ Crear/editar emisores de SU empresa
- ✅ Crear/editar destinatarios de SU empresa
- ✅ Asignar repartidores a órdenes de SU empresa
- ✅ Ver estadísticas de SU empresa
- ✅ Chat con repartidores de SU empresa
- ✅ Ajustes de envíos de SU empresa
- ❌ NO puede ver otras empresas
- ❌ NO puede crear empresas
- ❌ NO puede acceder al Super-Admin Dashboard

---

### 🔵 REPARTIDOR
**Ejemplos:**
- `repartidor@paqueteria.com`
- `tallercell0133@gmail.com` (Omar Jones)

**Acceso:** Solo Móvil (Android/iOS)  
**Panel:** App Móvil de Repartidor

**Funciones:**
- ✅ Ver órdenes asignadas a él
- ✅ Actualizar estado de órdenes
- ✅ Subir fotos de entrega
- ✅ Chat con administrador de su empresa
- ✅ Ver detalles de destinatarios
- ✅ Escanear QR de paquetes
- ❌ NO puede acceder desde Web (bloqueado)

---

## 🚀 FLUJO DE TRABAJO

### 1. TÚ (Super-Admin)
1. Accedes con `admin@administrador.com`
2. Ves el **Super-Admin Dashboard**
3. Creas una nueva empresa (cliente)
4. Le asignas un email de admin (ej: `empresa1@cliente.com`)
5. Le das las credenciales al cliente

### 2. CLIENTE (Admin de Empresa)
1. Accede con su email (ej: `empresa1@cliente.com`)
2. Ve el **Panel de Administración** normal
3. Crea emisores, destinatarios, órdenes
4. Asigna repartidores a sus órdenes
5. Solo ve SUS datos, no los de otras empresas

### 3. REPARTIDOR
1. Accede desde la app móvil
2. Ve solo las órdenes asignadas a él
3. Actualiza estados y sube fotos
4. NO puede acceder desde web

---

## 🔒 SEGURIDAD

### Detección de Super-Admin
El sistema detecta al Super-Admin por email exacto:
```dart
final adminEmails = {
  'admin@administrador.com',  // SOLO ESTE
};
```

### Aislamiento de Datos (Multi-tenancy)
- Cada empresa tiene un `tenant_id` único
- Los datos están aislados por `tenant_id`
- Row Level Security (RLS) asegura que cada empresa solo vea sus datos
- El Super-Admin puede ver TODOS los `tenant_id`

### Bloqueo de Plataforma
- Repartidores: Bloqueados en Web, solo móvil
- Administradores: Solo Web, no móvil
- Super-Admin: Solo Web

---

## 📝 NOTAS IMPORTANTES

1. **SOLO** `admin@administrador.com` es Super-Admin
2. **TODOS** los demás admins son administradores de empresa
3. Cada empresa es independiente y aislada
4. El Super-Admin puede vender el software a múltiples clientes
5. Cada cliente solo ve sus propios datos

---

## 🛠️ ARCHIVOS CLAVE

- **Login:** `lib/screens/login_supabase_screen.dart`
  - Detecta Super-Admin por email
  - Redirige al panel correcto según rol y email

- **Super-Admin Dashboard:** `lib/screens/super_admin_dashboard_screen.dart`
  - Panel de gestión de empresas
  - Solo accesible por `admin@administrador.com`

- **Admin Dashboard:** `lib/widgets/shared_layout.dart`
  - Panel normal de administración
  - Usado por todos los admins de empresas

- **Tabla Tenants:** Supabase → `tenants`
  - Almacena información de cada empresa/cliente
  - Cada fila es una empresa independiente

---

**Última actualización:** 21 de Octubre, 2025

