# LogiFlow Pro - Landing Page

## 🚀 Descripción

Página web profesional y moderna para **LogiFlow Pro**, el sistema de gestión logística que revoluciona empresas de paquetería.

## 📋 Características

✅ **Diseño Moderno**: Interfaz atractiva con gradientes, animaciones y efectos visuales  
✅ **Totalmente Responsivo**: Funciona perfectamente en desktop, tablet y móvil  
✅ **Navegación Intuitiva**: Menú sticky con smooth scroll  
✅ **Secciones Completas**:
- Hero con llamado a la acción
- Funcionalidades del sistema
- Capturas de pantalla (Dashboard Web + App Repartidor)
- Precios (Prueba gratis + Licencia de por vida)
- Descargas de apps móviles
- Formulario de solicitud de cuenta
- Contacto
- Footer completo

✅ **Formulario Funcional**: Validación de datos y sistema de notificaciones  
✅ **Optimizado para SEO**: Etiquetas semánticas y meta tags

## 📁 Estructura de Archivos

```
landing_page/
├── index.html          # Página principal
├── styles.css          # Estilos CSS
├── script.js           # JavaScript para interactividad
├── assets/             # Carpeta para imágenes
│   ├── logo.png                   # Logo de LogiFlow Pro (copia 1.png aquí)
│   ├── dashboard-preview.png      # Preview del dashboard en hero
│   ├── dashboard-full.png         # Captura completa del dashboard
│   ├── app-repartidor.png         # Captura de la app repartidor
│   └── phone-mockup.png           # Mockup del teléfono con la app
└── README.md           # Este archivo
```

## 🎨 Imágenes Necesarias

Necesitas agregar las siguientes imágenes en la carpeta `assets/`:

### 1. **logo.png**
- Copia el archivo `1.png` desde `Black and White Minimalist Professional Initial Logo`
- Renómbralo a `logo.png`
- Este es el logo principal que aparece en header y footer

### 2. **dashboard-preview.png**
- Captura de pantalla del dashboard web (sección principal)
- Tamaño recomendado: 1200x800px
- Se usa en el Hero Section

### 3. **dashboard-full.png**
- Captura completa del dashboard web
- Tamaño recomendado: 1400x900px
- Se usa en la sección "Capturas de Pantalla"

### 4. **app-repartidor.png**
- Captura de la app móvil del repartidor
- Tamaño recomendado: 400x800px (vertical)
- Se usa en la sección "Capturas de Pantalla"

### 5. **phone-mockup.png**
- Mockup de un teléfono con la app
- Puedes usar herramientas como:
  - https://mockuphone.com/
  - https://smartmockups.com/
  - O crear un mockup simple con Photoshop/Figma

## 🛠️ Cómo Usar

### Opción 1: Abrir Directamente
1. Navega a la carpeta `landing_page`
2. Haz doble clic en `index.html`
3. Se abrirá en tu navegador predeterminado

### Opción 2: Servidor Local
```bash
cd "/Users/cubcolexpress/Desktop/julio pauqteria sotfware/landing_page"

# Opción A: Python 3
python3 -m http.server 8000

# Opción B: Python 2
python -m SimpleHTTPServer 8000

# Opción C: Node.js (si tienes npx)
npx http-server -p 8000
```

Luego abre tu navegador en: `http://localhost:8000`

## 🔗 Configuración de Enlaces

### Botón "Iniciar Sesión"
Actualmente apunta a `http://localhost:57563` (tu app Flutter web)

**Para cambiar:**
Edita `index.html` línea 23:
```html
<a href="TU_URL_AQUI" class="btn btn-outline">Iniciar Sesión</a>
```

### Apps Móviles (Google Play / App Store)
Actualmente son placeholders (`#`)

**Para cambiar:**
Edita `index.html` líneas 351-352:
```html
<a href="URL_GOOGLE_PLAY" class="download-btn google-play">
<a href="URL_APP_STORE" class="download-btn app-store">
```

## 📧 Información de Contacto

La página usa:
- **Email**: soporte@logiflowpro.com
- **WhatsApp**: +1 (234) 567-8900
- **Horario**: Lunes a Viernes: 9:00 AM - 6:00 PM

**Para cambiar:**
Edita `index.html` en la sección "Contact" (líneas 448-476)

## 🎨 Personalización de Colores

Los colores principales están definidos en `styles.css` (líneas 13-20):

```css
:root {
    --primary-color: #5170FF;        /* Color principal (azul) */
    --primary-dark: #3d56d9;         /* Azul oscuro */
    --primary-light: #6b84ff;        /* Azul claro */
    --secondary-color: #4CAF50;      /* Verde */
    --accent-color: #FF9800;         /* Naranja */
    --success-color: #10B981;        /* Verde éxito */
    --danger-color: #DC2626;         /* Rojo */
}
```

Modifica estos valores para cambiar toda la paleta de colores.

## 📱 Responsive Breakpoints

- **Desktop**: > 1024px
- **Tablet**: 768px - 1024px
- **Mobile**: < 768px

## 🚀 Deploy en Producción

### Opción 1: Netlify (Gratis)
1. Sube la carpeta `landing_page` a GitHub
2. Conecta tu repo en [Netlify](https://netlify.com)
3. Deploy automático

### Opción 2: Vercel (Gratis)
1. Sube la carpeta `landing_page` a GitHub
2. Conecta tu repo en [Vercel](https://vercel.com)
3. Deploy automático

### Opción 3: Hosting Tradicional
1. Comprime la carpeta `landing_page` en .zip
2. Sube a tu hosting (cPanel, FTP, etc.)
3. Descomprime en la raíz del dominio

## 📝 Notas Importantes

1. **Formulario de Solicitud**:
   - Actualmente es simulado (no envía datos reales)
   - Para hacerlo funcional, debes configurar un backend
   - Opciones:
     - API propia en Node.js/Python/PHP
     - FormSubmit.co (servicio gratuito)
     - EmailJS (servicio gratuito)

2. **Imágenes Placeholder**:
   - Las imágenes actuales son rutas de ejemplo
   - Reemplázalas con capturas reales de tu sistema

3. **SEO**:
   - Agrega meta tags en `<head>`:
   ```html
   <meta name="description" content="LogiFlow Pro - Sistema profesional de gestión logística">
   <meta name="keywords" content="logística, paquetería, software, gestión">
   <meta property="og:image" content="/assets/dashboard-preview.png">
   ```

## 🔄 Próximas Mejoras

- [ ] Integrar Google Analytics
- [ ] Agregar chat en vivo (Tawk.to, Crisp, etc.)
- [ ] Implementar backend para formulario
- [ ] Agregar testimonios de clientes
- [ ] Crear blog/noticias
- [ ] Implementar sistema de afiliados

## 📞 Soporte

Si necesitas ayuda con la landing page:
- Email: soporte@logiflowpro.com
- WhatsApp: +1 (234) 567-8900

---

**Desarrollado con ❤️ para LogiFlow Pro**  
© 2025 LogiFlow Pro. Todos los derechos reservados.

