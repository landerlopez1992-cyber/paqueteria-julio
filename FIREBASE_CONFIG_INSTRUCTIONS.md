# 🔥 Configuración de Firebase para J Alvarez Express SVC

## 📋 Estado Actual
✅ **Pantalla de Login creada** con selector de rol (Administrador/Repartidor)  
✅ **Integración de Firebase Authentication** implementada  
✅ **Navegación basada en roles** configurada  
✅ **Dependencias de Firebase** instaladas  

## 🚨 IMPORTANTE: Configuración de Credenciales

### 1. Obtener Credenciales Reales de Firebase

Para que la aplicación funcione correctamente, necesitas obtener las credenciales reales de tu proyecto Firebase:

1. **Ve a la [Consola de Firebase](https://console.firebase.google.com/)**
2. **Selecciona tu proyecto:** `paqueteria-web-app`
3. **Ve a Configuración del proyecto** (ícono de engranaje)
4. **En la pestaña "General"**, busca la sección "Tus aplicaciones"
5. **Si no tienes una app web, crea una:**
   - Haz clic en "Agregar app" → "Web" (</>)
   - Registra la app con el nombre: `J Alvarez Express SVC`
   - Copia las credenciales que aparecen

### 2. Actualizar firebase_simple_config.dart

Reemplaza las credenciales en `/lib/firebase_simple_config.dart` con las reales:

```dart
static FirebaseOptions get webOptions {
  return const FirebaseOptions(
    apiKey: 'TU_API_KEY_REAL',           // ← Reemplazar
    appId: 'TU_APP_ID_REAL',             // ← Reemplazar  
    messagingSenderId: 'TU_SENDER_ID',   // ← Reemplazar
    projectId: 'paqueteria-web-app',     // ← Ya está correcto
    authDomain: 'paqueteria-web-app.firebaseapp.com', // ← Ya está correcto
    storageBucket: 'paqueteria-web-app.appspot.com',  // ← Ya está correcto
  );
}
```

### 3. Verificar Configuración de Authentication

Asegúrate de que en Firebase Console:
- **Authentication** esté habilitado
- **Email/Password** esté habilitado como método de sign-in
- Los usuarios de prueba estén creados (ya los creamos con el script Python)

## 🧪 Credenciales de Prueba

Una vez configurado Firebase correctamente, puedes usar estas credenciales:

### 👨‍💼 Administrador
- **Email:** `admin@paqueteria.com`
- **Password:** `Admin123!`
- **Rol:** Seleccionar "ADMINISTRADOR" en el login

### 🚚 Repartidor  
- **Email:** `repartidor@paqueteria.com`
- **Password:** `Rep123!`
- **Rol:** Seleccionar "REPARTIDOR" en el login

## 🎯 Características Implementadas

### ✅ Pantalla de Login
- **Nombre de la app:** "J Alvarez Express SVC"
- **Selector de rol:** Administrador/Repartidor
- **Validación de credenciales** con Firebase Auth
- **Verificación de rol** contra Firestore
- **Diseño profesional** con colores corporativos
- **Credenciales de prueba** mostradas en pantalla

### ✅ Integración Firebase
- **Firebase Authentication** para login
- **Cloud Firestore** para verificar roles de usuario
- **Navegación automática** al dashboard después del login
- **Manejo de errores** con mensajes informativos

### ✅ Navegación por Roles
- **Dashboard personalizado** según el rol del usuario
- **Verificación de permisos** antes de mostrar contenido
- **Logout automático** si el rol no coincide

## 🚀 Próximos Pasos

1. **Configurar credenciales reales** de Firebase
2. **Probar login** con usuarios de prueba
3. **Implementar funcionalidades específicas** por rol
4. **Conectar con Firestore** para datos reales
5. **Agregar más validaciones** de seguridad

## 🛠️ Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en Chrome
flutter run -d chrome

# Verificar configuración
flutter doctor
```

## 📞 Soporte

Si tienes problemas con la configuración:
1. Verifica que Firebase esté correctamente configurado
2. Asegúrate de que Authentication esté habilitado
3. Confirma que las credenciales sean correctas
4. Revisa la consola del navegador para errores

---

**¡La pantalla de login está lista! Solo necesitas las credenciales reales de Firebase para que funcione completamente.** 🎉


