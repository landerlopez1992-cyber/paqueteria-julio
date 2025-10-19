# 🔥 Guía de Configuración de Firebase para Paquetería App

## 📋 Paso 1: Crear Proyecto en Firebase Console

1. Ve a: https://console.firebase.google.com/
2. Haz clic en "Agregar proyecto" o "Add project"
3. Nombre del proyecto: **"paqueteria-app"** (o el que prefieras)
4. Acepta los términos
5. (Opcional) Desactiva Google Analytics si no lo necesitas
6. Haz clic en "Crear proyecto"

---

## 🌐 Paso 2: Registrar App Web

1. En el proyecto Firebase, haz clic en el ícono **Web** (`</>`)
2. Nombre de la app: **"Paquetería Web App"**
3. ✅ Marca "Also set up Firebase Hosting"
4. Haz clic en "Registrar app"
5. **IMPORTANTE:** Copia el objeto `firebaseConfig` que aparece

Ejemplo de lo que verás:
```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "paqueteria-app.firebaseapp.com",
  projectId: "paqueteria-app",
  storageBucket: "paqueteria-app.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef"
};
```

**⚠️ GUARDA ESTOS DATOS - Los necesitarás en el siguiente paso**

---

## 🗄️ Paso 3: Activar Firestore Database

1. En el menú lateral de Firebase Console, ve a **"Firestore Database"**
2. Haz clic en "Create database" o "Crear base de datos"
3. Selecciona **"Start in test mode"** (modo de prueba)
   - Esto permite lectura/escritura sin autenticación por 30 días
4. Selecciona la región: **"us-central"** (o la más cercana a ti)
5. Haz clic en "Enable" o "Habilitar"

---

## 📊 Paso 4: Crear las Colecciones (Tablas)

Una vez que Firestore esté activo:

### Colección: `emisores`
1. Haz clic en "Start collection" o "Iniciar colección"
2. Collection ID: **`emisores`**
3. Agrega un documento de ejemplo:
   - Document ID: Auto-ID
   - Campos:
     ```
     nombre: "Juan Pérez"
     telefono: "555-1234"
     direccion: "Calle A #100"
     email: "juan@email.com"
     createdAt: timestamp (selecciona la fecha/hora actual)
     ```
4. Haz clic en "Save"

### Colección: `receptores`
1. Haz clic en "Start collection"
2. Collection ID: **`receptores`**
3. Agrega un documento de ejemplo:
   - Document ID: Auto-ID
   - Campos:
     ```
     nombre: "María González"
     telefono: "555-3456"
     direccion: "Calle X #400"
     email: "maria@email.com"
     createdAt: timestamp (selecciona la fecha/hora actual)
     ```
4. Haz clic en "Save"

### Colección: `ordenes`
1. Haz clic en "Start collection"
2. Collection ID: **`ordenes`**
3. Agrega un documento de ejemplo:
   - Document ID: Auto-ID
   - Campos:
     ```
     emisorNombre: "Juan Pérez"
     receptorNombre: "María González"
     descripcion: "Paquete de documentos importantes"
     direccionDestino: "Calle Principal #123, Ciudad"
     estado: "EN TRANSITO"
     fechaCreacion: timestamp (selecciona la fecha/hora actual)
     fechaEntrega: null
     observaciones: ""
     createdBy: "Super-Admin"
     ```
4. Haz clic en "Save"

---

## 🔐 Paso 5: Configurar Reglas de Seguridad

1. En Firestore, ve a la pestaña **"Rules"** o **"Reglas"**
2. Reemplaza las reglas con esto:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura y escritura a todos por ahora (SOLO PARA DESARROLLO)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. Haz clic en "Publish" o "Publicar"

**⚠️ IMPORTANTE:** Estas reglas permiten acceso total. Más adelante cambiaremos a reglas de seguridad apropiadas.

---

## ✅ Paso 6: ¡Listo para Integrar con Flutter!

Una vez completados todos los pasos anteriores, ejecuta el siguiente comando en tu terminal:

```bash
cd "/Users/cubcolexpress/Desktop/julio pauqteria sotfware/paqueteria_app"
chmod +x configure_firebase.sh
./configure_firebase.sh
```

Este script te pedirá los datos de `firebaseConfig` que copiaste en el Paso 2.

---

## 📝 Resumen de lo que necesitas:

- ✅ Proyecto Firebase creado
- ✅ App Web registrada
- ✅ `firebaseConfig` copiado
- ✅ Firestore activado
- ✅ Colecciones creadas: `emisores`, `receptores`, `ordenes`
- ✅ Reglas de seguridad configuradas

---

## 🆘 ¿Problemas?

Si tienes algún problema en algún paso, avísame y te ayudo a resolverlo.

¡Una vez completado todo, podrás usar Firebase en tu app! 🚀



