# 🚀 LogiFlow Pro - Sistema de Lanzamiento

## 📋 Cómo usar el sistema completo

### 1. **Landing Page (Marketing)**
```bash
# Opción A: Servidor Node.js (Recomendado)
cd landing_page
npm start
# Abre: http://localhost:3000

# Opción B: Abrir directamente
open index.html
```

### 2. **App Flutter (Sistema Principal)**
```bash
# En VS Code: F5 o "Run and Debug"
# O manualmente:
cd paqueteria_app
flutter run -d web --web-port 57563
# Abre: http://localhost:57563
```

## 🎯 Flujo de Usuario

1. **Cliente ve Landing Page** → `http://localhost:3000`
2. **Presiona "Iniciar Sesión"** → Redirige a `http://localhost:57563`
3. **Login en App Flutter** → Acceso al sistema

## ⚙️ Configuración VS Code

### Launch Configurations:
- **"Launch Landing Page"** → Ejecuta servidor de landing page
- **"Launch Flutter App"** → Ejecuta app Flutter

### Uso:
1. Presiona `F5` o `Ctrl+Shift+D`
2. Selecciona "Launch Landing Page"
3. Se abre automáticamente en el navegador

## 🔗 Enlaces Importantes

- **Landing Page**: `http://localhost:3000`
- **App Flutter**: `http://localhost:57563`
- **Launch Page**: `http://localhost:3000/launch.html`

## 📱 Botones de Navegación

### En Landing Page:
- **"Iniciar Sesión"** → Va a `http://localhost:57563` (App Flutter)
- **"Solicitar Cuenta"** → Formulario de contacto

### En Launch Page:
- **"Ver Landing Page"** → Va a `index.html`
- **"Ir a Login App"** → Va a `http://localhost:57563`

## 🛠️ Comandos Útiles

```bash
# Instalar dependencias (si es necesario)
npm install

# Ejecutar landing page
npm start

# Ejecutar app Flutter
flutter run -d web --web-port 57563

# Ejecutar ambos (terminal separado)
npm start & flutter run -d web --web-port 57563
```

## 🎨 Estructura de Archivos

```
landing_page/
├── index.html          # Landing page principal
├── launch.html         # Página de lanzamiento
├── server.js           # Servidor Node.js
├── package.json        # Configuración npm
├── .vscode/
│   └── launch.json     # Configuración VS Code
└── assets/             # Imágenes y recursos
```

## ✅ Verificación

1. ✅ Landing page se abre en `http://localhost:3000`
2. ✅ Botón "Iniciar Sesión" redirige a `http://localhost:57563`
3. ✅ App Flutter funciona en puerto 57563
4. ✅ Navegación entre páginas funciona correctamente

## 🚨 Solución de Problemas

### Si el puerto 57563 está ocupado:
```bash
flutter run -d web --web-port 57564
# Luego actualiza el enlace en index.html
```

### Si el servidor no inicia:
```bash
# Verificar que Node.js esté instalado
node --version

# Instalar dependencias
npm install
```

¡**Sistema listo para usar!** 🎉
