# Sistema de Chat de Soporte en Tiempo Real

## 📋 Descripción

Sistema de mensajería en tiempo real que conecta a los repartidores con los administradores del sistema, permitiendo comunicación directa para resolver dudas y problemas.

## 🎯 Características

### Para Repartidores (Móvil)
- ✅ Acceso rápido desde el AppBar (icono de chat)
- ✅ Conversación directa con administradores
- ✅ Mensajes en tiempo real
- ✅ Notificaciones de mensajes no leídos
- ✅ Interfaz amigable y sencilla
- ✅ Historial completo de conversaciones

### Para Administradores (Dashboard)
- ✅ Vista de todas las conversaciones activas
- ✅ Lista organizada por última actividad
- ✅ Contador de mensajes no leídos
- ✅ Capacidad de cerrar/reabrir conversaciones
- ✅ Mensajes en tiempo real
- ✅ Información del repartidor (nombre, foto, email)

## 🗄️ Base de Datos

### Tablas Creadas

#### `conversaciones_soporte`
```sql
- id (UUID, PK)
- repartidor_id (UUID, FK -> usuarios)
- estado (TEXT: 'ABIERTA' | 'CERRADA')
- ultimo_mensaje_fecha (TIMESTAMP)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### `mensajes_soporte`
```sql
- id (UUID, PK)
- conversacion_id (UUID, FK -> conversaciones_soporte)
- remitente_id (UUID, FK -> usuarios)
- mensaje (TEXT)
- leido (BOOLEAN)
- created_at (TIMESTAMP)
```

### Triggers Automáticos
- **actualizar_ultimo_mensaje**: Actualiza `ultimo_mensaje_fecha` en la conversación cuando se envía un mensaje nuevo.

### Seguridad (RLS)
- Los repartidores solo pueden ver sus propias conversaciones
- Los administradores pueden ver todas las conversaciones
- Los usuarios solo pueden enviar mensajes en sus conversaciones
- Todos pueden marcar mensajes como leídos

## 📦 Instalación

### 1. Ejecutar SQL en Supabase

Copia y ejecuta el contenido del archivo `create_chat_system.sql` en el SQL Editor de Supabase:

```bash
# Archivo: create_chat_system.sql
```

Esto creará:
- ✅ Tablas necesarias
- ✅ Índices para rendimiento
- ✅ Triggers automáticos
- ✅ Políticas de seguridad (RLS)

### 2. Verificar en Supabase

1. Ve a **Database** → **Tables**
2. Confirma que existen:
   - `conversaciones_soporte`
   - `mensajes_soporte`
3. Ve a **Database** → **Triggers**
4. Confirma que existe:
   - `trigger_actualizar_ultimo_mensaje`

## 🚀 Uso

### Para Repartidores

1. **Abrir Chat**
   - Toca el icono de chat (💬) en el AppBar
   - Se abrirá automáticamente una conversación con soporte

2. **Enviar Mensajes**
   - Escribe en el campo de texto
   - Presiona el botón de enviar (✉️) o Enter
   - El mensaje aparecerá inmediatamente

3. **Ver Mensajes**
   - Los mensajes de soporte aparecen a la izquierda
   - Tus mensajes aparecen a la derecha (azul)
   - Scroll para ver historial completo

### Para Administradores

1. **Acceder al Chat**
   - Desde el menú lateral, selecciona **"Chat Soporte"**
   - Verás todas las conversaciones activas

2. **Ver Conversaciones**
   - Las conversaciones se ordenan por última actividad
   - El badge rojo muestra mensajes no leídos
   - Toca una conversación para abrirla

3. **Responder**
   - Escribe en el campo de texto
   - Presiona enviar
   - El repartidor verá tu respuesta en tiempo real

4. **Gestionar Conversaciones**
   - Menú (⋮) → **Cerrar conversación**: Marca como resuelta
   - Menú (⋮) → **Reabrir conversación**: Si se necesita más soporte

## 🔄 Sincronización en Tiempo Real

El sistema utiliza **Supabase Realtime** para:
- ✅ Actualizar mensajes instantáneamente
- ✅ Notificar nuevas conversaciones
- ✅ Sincronizar estado de lectura
- ✅ Actualizar lista de conversaciones

No requiere refresh manual - todo es automático!

## 🎨 Diseño

### Colores Oficiales (Cubalink23)
- **Mensajes del Admin**: Azul primario (#1976D2)
- **Mensajes del Repartidor**: Naranja (#FF9800)
- **Fondos**: Blanco (#FFFFFF)
- **Texto Principal**: Negro (#2C2C2C)
- **Texto Secundario**: Gris (#666666)

### Iconos
- 💬 Chat de soporte
- 👤 Repartidor
- 🛡️ Administrador
- ✉️ Enviar mensaje
- ✅ Conversación cerrada
- 🔄 Reabrir conversación

## 📱 Pantallas

### `ChatSoporteScreen` (Repartidor - Móvil)
- Ubicación: `lib/screens/chat_soporte_screen.dart`
- Acceso: Desde AppBar de `RepartidorMobileScreen`

### `ChatAdminScreen` (Administrador - Web/Desktop)
- Ubicación: `lib/screens/chat_admin_screen.dart`
- Acceso: Desde menú lateral → "Chat Soporte"

### `ChatAdminConversacionScreen` (Conversación individual)
- Ubicación: Dentro de `chat_admin_screen.dart`
- Acceso: Al tocar una conversación en `ChatAdminScreen`

## 🔧 Configuración

### Modificar Estados de Conversación

En `create_chat_system.sql`, línea donde se define el campo `estado`:
```sql
estado TEXT NOT NULL DEFAULT 'ABIERTA'
```

Valores permitidos:
- `'ABIERTA'`: Conversación activa
- `'CERRADA'`: Conversación resuelta

### Personalizar Límites

```dart
// En chat_admin_screen.dart
// Línea donde se cargan conversaciones:
.order('ultimo_mensaje_fecha', ascending: false)
// .limit(50) // Agregar para limitar a 50 conversaciones
```

## 🐛 Troubleshooting

### Los mensajes no se envían
1. Verifica que las políticas RLS estén activas
2. Confirma que el usuario está autenticado
3. Revisa la consola para errores de Supabase

### No se actualiza en tiempo real
1. Verifica conexión a internet
2. Confirma que Realtime está habilitado en Supabase
3. Revisa que el canal se suscribió correctamente

### Mensajes duplicados
1. Asegúrate de hacer `unsubscribe()` en `dispose()`
2. Evita suscripciones múltiples al mismo canal

## 📊 Métricas y Analytics

Para agregar métricas del chat:

```sql
-- Mensajes por día
SELECT 
  DATE(created_at) as fecha,
  COUNT(*) as total_mensajes
FROM mensajes_soporte
GROUP BY DATE(created_at)
ORDER BY fecha DESC;

-- Tiempo promedio de respuesta
SELECT 
  AVG(EXTRACT(EPOCH FROM (admin_msg.created_at - repartidor_msg.created_at))) / 60 as minutos_promedio
FROM mensajes_soporte admin_msg
JOIN mensajes_soporte repartidor_msg 
  ON admin_msg.conversacion_id = repartidor_msg.conversacion_id
WHERE admin_msg.remitente_id IN (SELECT id FROM usuarios WHERE rol = 'ADMINISTRADOR')
  AND repartidor_msg.remitente_id IN (SELECT id FROM usuarios WHERE rol = 'REPARTIDOR')
  AND admin_msg.created_at > repartidor_msg.created_at;
```

## 📝 Notas Importantes

1. **Seguridad**: Las políticas RLS garantizan que cada usuario solo vea sus conversaciones
2. **Performance**: Los índices están optimizados para búsquedas rápidas
3. **Escalabilidad**: El sistema soporta miles de conversaciones simultáneas
4. **Cleanup**: Considera agregar un job para archivar conversaciones antiguas

## 🚀 Próximas Mejoras Sugeridas

- [ ] Adjuntar imágenes/archivos
- [ ] Notificaciones push
- [ ] Indicador "escribiendo..."
- [ ] Búsqueda de mensajes
- [ ] Exportar historial de chat
- [ ] Chat en grupo (múltiples administradores)
- [ ] Respuestas rápidas predefinidas
- [ ] Traducción automática

## 👨‍💻 Soporte Técnico

Para problemas o preguntas sobre el sistema de chat, consulta:
- Documentación de Supabase Realtime
- Logs de la aplicación (`print` statements en desarrollo)
- SQL Editor en Supabase para verificar datos

---

**Versión**: 1.0.0  
**Última actualización**: Octubre 2025  
**Autor**: Sistema de Paquetería J Alvarez Express SVC

