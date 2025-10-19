# 🔥 Configuración Rápida de Firebase

## 🚀 Pasos Rápidos:

### 1️⃣ Abre Firebase Console
```
https://console.firebase.google.com/
```

### 2️⃣ Crea un Nuevo Proyecto
- Nombre: **paqueteria-app** (o el que prefieras)
- Deshabilita Google Analytics (opcional)

### 3️⃣ Agrega una App Web
1. Haz clic en el ícono `</>` (Web)
2. Nombre: **Paquetería Web App**
3. ✅ Marca "Also set up Firebase Hosting"
4. **Copia el `firebaseConfig`** que aparece

### 4️⃣ Activa Firestore
1. Menú lateral → **Firestore Database**
2. **Create database**
3. Modo: **Test mode** ✅
4. Región: **us-central** (o la más cercana)

### 5️⃣ Crea las Colecciones
Crea estas 3 colecciones con un documento de ejemplo cada una:

**`emisores`:**
```javascript
{
  nombre: "Juan Pérez",
  telefono: "555-1234",
  direccion: "Calle A #100",
  email: "juan@email.com",
  createdAt: timestamp
}
```

**`receptores`:**
```javascript
{
  nombre: "María González",
  telefono: "555-3456",
  direccion: "Calle X #400",
  email: "maria@email.com",
  createdAt: timestamp
}
```

**`ordenes`:**
```javascript
{
  emisorNombre: "Juan Pérez",
  receptorNombre: "María González",
  descripcion: "Paquete de documentos",
  direccionDestino: "Calle Principal #123",
  estado: "EN TRANSITO",
  fechaCreacion: timestamp,
  fechaEntrega: null,
  observaciones: "",
  createdBy: "Super-Admin"
}
```

### 6️⃣ Ejecuta el Script de Configuración

En tu terminal:

```bash
cd "/Users/cubcolexpress/Desktop/julio pauqteria sotfware/paqueteria_app"
./configure_firebase.sh
```

El script te pedirá estos datos del paso 3:
- API Key
- Auth Domain
- Project ID
- Storage Bucket
- Messaging Sender ID
- App ID

### 7️⃣ ¡Listo! Ejecuta tu App

```bash
flutter run -d chrome
```

---

## 📋 Checklist:

- [ ] Proyecto Firebase creado
- [ ] App Web registrada
- [ ] `firebaseConfig` copiado
- [ ] Firestore activado (Test mode)
- [ ] 3 colecciones creadas (emisores, receptores, ordenes)
- [ ] Script `configure_firebase.sh` ejecutado
- [ ] App corriendo con Firebase conectado

---

## 🆘 ¿Problemas?

### Error: "Firebase not initialized"
→ Asegúrate de que las credenciales en el script sean correctas

### Error: "Permission denied"
→ Verifica las reglas de Firestore (deben estar en Test mode)

### Error: "Collection doesn't exist"
→ Crea las 3 colecciones manualmente en Firebase Console

---

## 📚 Documentación Completa

Para instrucciones detalladas, revisa: `FIREBASE_SETUP.md`

---

¡Disfruta tu app de paquetería con Firebase! 🚀📦



