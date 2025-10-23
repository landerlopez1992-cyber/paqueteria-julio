// ==========================================================================
// LOGIFLOW PRO - LANDING PAGE JAVASCRIPT
// ==========================================================================

document.addEventListener('DOMContentLoaded', function() {
    
    // ======================================================================
    // MOBILE MENU TOGGLE
    // ======================================================================
    const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
    const navMenu = document.querySelector('.nav-menu');
    
    if (mobileMenuToggle) {
        mobileMenuToggle.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            this.classList.toggle('active');
        });
    }
    
    // ======================================================================
    // SMOOTH SCROLL FOR NAVIGATION LINKS
    // ======================================================================
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            
            // Skip if it's just "#" (for placeholder links)
            if (href === '#') {
                e.preventDefault();
                return;
            }
            
            const targetElement = document.querySelector(href);
            
            if (targetElement) {
                e.preventDefault();
                
                // Close mobile menu if open
                if (navMenu && navMenu.classList.contains('active')) {
                    navMenu.classList.remove('active');
                    mobileMenuToggle.classList.remove('active');
                }
                
                // Scroll to target with offset for fixed header
                const headerOffset = 80;
                const elementPosition = targetElement.getBoundingClientRect().top;
                const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
                
                window.scrollTo({
                    top: offsetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // ======================================================================
    // HEADER SCROLL EFFECT
    // ======================================================================
    const header = document.querySelector('.header');
    let lastScroll = 0;
    
    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        
        if (currentScroll > 100) {
            header.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)';
        } else {
            header.style.boxShadow = '0 1px 2px 0 rgba(0, 0, 0, 0.05)';
        }
        
        lastScroll = currentScroll;
    });
    
    // ======================================================================
    // SCREENSHOTS TABS
    // ======================================================================
    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            
            // Remove active class from all buttons and contents
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));
            
            // Add active class to clicked button and corresponding content
            this.classList.add('active');
            document.querySelector(`[data-content="${tabName}"]`).classList.add('active');
        });
    });
    
    // ======================================================================
    // SCREENSHOT GALLERY THUMBNAILS
    // ======================================================================
    const thumbnails = document.querySelectorAll('.thumbnail');
    const mainScreenshot = document.querySelector('.screenshot-main img');
    
    thumbnails.forEach(thumbnail => {
        thumbnail.addEventListener('click', function() {
            const newSrc = this.getAttribute('data-src');
            
            // Remove active class from all thumbnails
            thumbnails.forEach(thumb => thumb.classList.remove('active'));
            
            // Add active class to clicked thumbnail
            this.classList.add('active');
            
            // Change main image with smooth transition
            if (mainScreenshot) {
                mainScreenshot.style.opacity = '0.7';
                setTimeout(() => {
                    mainScreenshot.src = newSrc;
                    mainScreenshot.style.opacity = '1';
                }, 150);
            }
        });
    });
    
    // ======================================================================
    // MOBILE GALLERY THUMBNAILS
    // ======================================================================
    const mobileThumbnails = document.querySelectorAll('.mobile-thumbnail');
    const mobileMainScreenshot = document.querySelector('.mobile-main img');
    
    mobileThumbnails.forEach(thumbnail => {
        thumbnail.addEventListener('click', function() {
            const newSrc = this.getAttribute('data-src');
            
            // Remove active class from all mobile thumbnails
            mobileThumbnails.forEach(thumb => thumb.classList.remove('active'));
            
            // Add active class to clicked thumbnail
            this.classList.add('active');
            
            // Change main mobile image with smooth transition
            if (mobileMainScreenshot) {
                mobileMainScreenshot.style.opacity = '0.7';
                setTimeout(() => {
                    mobileMainScreenshot.src = newSrc;
                    mobileMainScreenshot.style.opacity = '1';
                }, 150);
            }
        });
    });
    
    // ======================================================================
    // FORM VALIDATION & SUBMISSION
    // ======================================================================
    const requestForm = document.getElementById('requestForm');
    
    if (requestForm) {
        requestForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get form data
            const formData = {
                nombre: document.getElementById('nombre').value,
                empresa: document.getElementById('empresa').value,
                email: document.getElementById('email').value,
                telefono: document.getElementById('telefono').value,
                pais: document.getElementById('pais').value,
                repartidores: document.getElementById('repartidores').value,
                mensaje: document.getElementById('mensaje').value
            };
            
            // Validate required fields
            if (!formData.nombre || !formData.empresa || !formData.email || !formData.telefono || !formData.pais) {
                showNotification('Por favor completa todos los campos obligatorios', 'error');
                return;
            }
            
            // Validate email format
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(formData.email)) {
                showNotification('Por favor ingresa un email válido', 'error');
                return;
            }
            
            // Show loading state
            const submitButton = requestForm.querySelector('button[type="submit"]');
            const originalButtonText = submitButton.innerHTML;
            submitButton.innerHTML = '<svg class="animate-spin" width="20" height="20" fill="currentColor" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Enviando...';
            submitButton.disabled = true;
            
            // Simulate form submission (replace with actual API call)
            setTimeout(() => {
                console.log('Form data:', formData);
                
                // Show success message
                showNotification('¡Solicitud enviada exitosamente! Te contactaremos pronto.', 'success');
                
                // Reset form
                requestForm.reset();
                
                // Reset button
                submitButton.innerHTML = originalButtonText;
                submitButton.disabled = false;
                
                // In production, you would send this data to your backend:
                /*
                fetch('/api/solicitar-cuenta', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(formData)
                })
                .then(response => response.json())
                .then(data => {
                    showNotification('¡Solicitud enviada exitosamente!', 'success');
                    requestForm.reset();
                })
                .catch(error => {
                    showNotification('Error al enviar la solicitud. Inténtalo de nuevo.', 'error');
                })
                .finally(() => {
                    submitButton.innerHTML = originalButtonText;
                    submitButton.disabled = false;
                });
                */
            }, 1500);
        });
    }
    
    // ======================================================================
    // NOTIFICATION SYSTEM
    // ======================================================================
    function showNotification(message, type = 'info') {
        // Remove existing notifications
        const existingNotification = document.querySelector('.notification');
        if (existingNotification) {
            existingNotification.remove();
        }
        
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20">
                    ${type === 'success' 
                        ? '<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"/>'
                        : '<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"/>'
                    }
                </svg>
                <span>${message}</span>
            </div>
            <button class="notification-close" onclick="this.parentElement.remove()">
                <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"/>
                </svg>
            </button>
        `;
        
        // Add styles for notification
        const style = document.createElement('style');
        style.textContent = `
            .notification {
                position: fixed;
                top: 100px;
                right: 20px;
                max-width: 400px;
                padding: 1rem 1.5rem;
                background: white;
                border-radius: 0.75rem;
                box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
                z-index: 9999;
                animation: slideIn 0.3s ease-out;
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 1rem;
            }
            
            .notification-success {
                border-left: 4px solid #10B981;
            }
            
            .notification-error {
                border-left: 4px solid #DC2626;
            }
            
            .notification-content {
                display: flex;
                align-items: center;
                gap: 0.75rem;
                flex: 1;
            }
            
            .notification-success svg {
                color: #10B981;
            }
            
            .notification-error svg {
                color: #DC2626;
            }
            
            .notification-close {
                background: none;
                border: none;
                cursor: pointer;
                padding: 0.25rem;
                color: #6B7280;
                transition: color 0.2s;
            }
            
            .notification-close:hover {
                color: #111827;
            }
            
            @keyframes slideIn {
                from {
                    transform: translateX(100%);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }
            
            @keyframes slideOut {
                from {
                    transform: translateX(0);
                    opacity: 1;
                }
                to {
                    transform: translateX(100%);
                    opacity: 0;
                }
            }
        `;
        
        if (!document.querySelector('.notification-styles')) {
            style.className = 'notification-styles';
            document.head.appendChild(style);
        }
        
        // Add to page
        document.body.appendChild(notification);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease-out';
            setTimeout(() => notification.remove(), 300);
        }, 5000);
    }
    
    // ======================================================================
    // INTERSECTION OBSERVER FOR ANIMATIONS
    // ======================================================================
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);
    
    // Observe feature cards, pricing cards, etc.
    document.querySelectorAll('.feature-card, .pricing-card, .benefit-item').forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
    
    // ======================================================================
    // DOWNLOAD BUTTON TRACKING (Optional Analytics)
    // ======================================================================
    document.querySelectorAll('.download-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            const platform = this.classList.contains('google-play') ? 'Android' : 'iOS';
            console.log(`Download clicked: ${platform}`);
            
            // In production, you would track this event:
            // gtag('event', 'download_app', { 'platform': platform });
            // or
            // analytics.track('Download App', { platform: platform });
        });
    });
    
    // ======================================================================
    // CONSOLE MESSAGE
    // ======================================================================
    console.log('%c🚀 LogiFlow Pro', 'font-size: 24px; font-weight: bold; color: #5170FF;');
    console.log('%cSistema de Gestión Logística Profesional', 'font-size: 14px; color: #6B7280;');
    console.log('%c¿Interesado en el código? Contáctanos en soporte@logiflowpro.com', 'font-size: 12px; color: #4CAF50;');
});



// Resolve login URL based on environment (local vs GitHub Pages)
(function(){
  const loginLink = document.getElementById('login-link');
  if (!loginLink) return;
  const isGhPages = location.host.includes('github.io');
  // If running on GitHub Pages, link to /paqueteria-julio/app/
  const ghUrl = location.origin + '/paqueteria-julio/app/';
  // Local default
  const localUrl = 'http://localhost:57563';
  if (isGhPages) {
    // Try to detect if /app/ exists, fallback to root
    fetch('/paqueteria-julio/app/index.html', { method: 'HEAD' })
      .then(r => { loginLink.href = r.ok ? ghUrl : (location.origin + '/paqueteria-julio/'); })
      .catch(() => { loginLink.href = location.origin + '/paqueteria-julio/'; });
  } else {
    loginLink.href = localUrl;
  }
})();
