# 🔑 SOLUCIÓN DEFINITIVA: Habilitar Identity Toolkit API

## 🚨 Problema
El error **"api-key-not-valid"** ocurre porque **Identity Toolkit API** no está habilitada en Google Cloud.

## ✅ Solución

### Paso 1: Ve a Google Cloud Console

1. **Abre:** https://console.cloud.google.com/
2. **Selecciona tu proyecto:** `paqueteria-web-app`

### Paso 2: Habilitar Identity Toolkit API

**Opción A - Enlace directo:**
1. Ve a: https://console.cloud.google.com/apis/library/identitytoolkit.googleapis.com
2. Asegúrate de que el proyecto `paqueteria-web-app` esté seleccionado
3. Haz clic en **"HABILITAR"**
4. Espera unos segundos a que se habilite

**Opción B - Desde el menú:**
1. En Google Cloud Console, ve a **"APIs & Services"** → **"Library"**
2. Busca: **"Identity Toolkit API"**
3. Haz clic en **"Identity Toolkit API"**
4. Haz clic en **"HABILITAR"**

### Paso 3: Verificar APIs Habilitadas

También asegúrate de que estén habilitadas:

1. **Identity Toolkit API** ✅ (obligatorio)
2. **Cloud Firestore API** ✅
3. **Firebase Authentication** (se habilita automáticamente)

### Paso 4: Probar Login

Una vez habilitada la Identity Toolkit API:

1. Espera 1-2 minutos para que se propague
2. Recarga la app en Chrome (F5)
3. Intenta login con:
   - Email: `admin@paqueteria.com`
   - Password: `Admin123!`
   - Rol: `ADMINISTRADOR`

---

## 🎯 Enlace directo para habilitar

**IMPORTANTE:** Haz clic aquí para habilitar directamente:

👉 https://console.cloud.google.com/apis/library/identitytoolkit.googleapis.com?project=paqueteria-web-app

**Asegúrate de:**
- Estar en el proyecto correcto
- Hacer clic en "HABILITAR"
- Esperar a que termine de habilitarse

---

## ⚠️ Nota

El error "api-key-not-valid" no significa que la API Key esté mal, sino que **la API Key no tiene permisos para usar Identity Toolkit** porque esa API no está habilitada en el proyecto.


