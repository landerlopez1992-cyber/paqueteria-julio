# 🔑 SOLUCIÓN: API Key Inválida

## 🚨 Problema Identificado
**Error:** `api-key-not-valid.-please-pass-a-valid-api-key`

**Causa:** La API Key que estamos usando no está autorizada para la app web.

## ✅ Solución Paso a Paso

### 📋 Paso 1: Obtener la API Key Correcta

1. **Ve a la Consola de Firebase:**
   - https://console.firebase.google.com/
   - Proyecto: `paqueteria-web-app`

2. **Ve a Configuración del Proyecto:**
   - Haz clic en el ícono de engranaje ⚙️
   - Selecciona **"Configuración del proyecto"**

3. **Ve a la pestaña "General":**
   - Busca la sección **"Tus aplicaciones"**
   - Deberías ver una app web (</>) con el nombre que registraste

4. **Si NO tienes una app web:**
   - Haz clic en **"Agregar app"** → **"Web"** (</>)
   - Nombre de la app: `J Alvarez Express SVC Web`
   - ✅ Marca "También configurar Firebase Hosting para esta app" (opcional)
   - Haz clic en **"Registrar app"**

5. **Copia la configuración:**
   ```javascript
   const firebaseConfig = {
     apiKey: "AIza...........XXXXXXX",  // ← Esta es la que necesitamos
     authDomain: "paqueteria-web-app.firebaseapp.com",
     projectId: "paqueteria-web-app",
     storageBucket: "paqueteria-web-app.firebasestorage.app",
     messagingSenderId: "569133655577",
     appId: "1:569133655577:web:XXXXXXXXXX"
   };
   ```

### 📋 Paso 2: Verificar restricciones de API

Si ya tienes la app web registrada:

1. **Ve a Google Cloud Console:**
   - https://console.cloud.google.com/
   - Selecciona el proyecto `paqueteria-web-app`

2. **Ve a APIs & Services → Credentials:**
   - Busca la API Key de tu proyecto
   - Haz clic en ella

3. **Verifica las restricciones:**
   - **Restricciones de aplicación:** Debe estar configurada para permitir HTTP referrers
   - **Restricciones de API:** Debe incluir:
     - Identity Toolkit API
     - Cloud Firestore API
     - Firebase Authentication API

4. **Si hay restricciones de HTTP referrers:**
   - Agrega: `localhost:*`
   - Agrega: `127.0.0.1:*`

### 📋 Paso 3: Actualizar la configuración en Flutter

Una vez que tengas la API Key correcta, actualiza el archivo:

**`lib/firebase_simple_config.dart`:**

```dart
static FirebaseOptions get webOptions {
  return const FirebaseOptions(
    apiKey: 'TU_NUEVA_API_KEY_AQUI',  // ← Actualiza esto
    appId: '1:569133655577:web:XXXXXXXXXX',
    messagingSenderId: '569133655577',
    projectId: 'paqueteria-web-app',
    authDomain: 'paqueteria-web-app.firebaseapp.com',
    storageBucket: 'paqueteria-web-app.firebasestorage.app',
  );
}
```

### 📋 Paso 4: Habilitar APIs necesarias

En Google Cloud Console:

1. **Ve a APIs & Services → Library**
2. **Busca y habilita:**
   - ✅ Identity Toolkit API
   - ✅ Cloud Firestore API  
   - ✅ Firebase Authentication API

## 🎯 Checklist de Verificación

Antes de probar nuevamente, verifica que:

- [ ] Tienes una app web registrada en Firebase Console
- [ ] La API Key es de la sección "Tus aplicaciones" → Web app
- [ ] Identity Toolkit API está habilitada
- [ ] Firebase Authentication → Email/Password está habilitado
- [ ] No hay restricciones HTTP referrer que bloqueen localhost
- [ ] El usuario `admin@paqueteria.com` existe en Authentication

## 📞 Siguiente Paso

1. Obtén la API Key correcta de la consola
2. Actualiza `firebase_simple_config.dart`
3. Ejecuta `flutter run -d chrome`
4. Prueba login con: `admin@paqueteria.com` / `Admin123!`

---

**Nota:** El error "api-key-not-valid" significa que la API Key no está autorizada para usar Firebase Authentication desde el dominio web. Esto es una medida de seguridad de Firebase.
