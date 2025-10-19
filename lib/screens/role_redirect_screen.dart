import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../config/app_colors.dart';
import 'login_supabase_screen.dart';
import 'dashboard_screen.dart';
import 'repartidor_mobile_screen.dart';

class RoleRedirectScreen extends StatefulWidget {
  final String userRole;
  final String userName;
  final String? userEmail;

  const RoleRedirectScreen({
    super.key,
    required this.userRole,
    required this.userName,
    this.userEmail,
  });

  @override
  State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
}

class _RoleRedirectScreenState extends State<RoleRedirectScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleRoleRedirect();
  }

  Future<void> _handleRoleRedirect() async {
    // DEBUG: Mostrar valores
    print('🔍 DEBUG RoleRedirect:');
    print('   - userRole: ${widget.userRole}');
    print('   - kIsWeb: $kIsWeb');
    print('   - Plataforma: ${kIsWeb ? "WEB" : "MÓVIL"}');
    
    // Verificar inmediatamente si hay conflicto de plataforma
    final hasConflict = (widget.userRole == 'ADMINISTRADOR' && !kIsWeb) || 
                       (widget.userRole == 'REPARTIDOR' && kIsWeb);
    
    print('   - hasConflict: $hasConflict');
    
    if (hasConflict) {
      print('⚠️ CONFLICTO DETECTADO: Mostrando mensaje');
      // Si hay conflicto, mostrar mensaje inmediatamente
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('✅ NO HAY CONFLICTO: Auto-redirigiendo');
      // Si no hay conflicto, pequeña pausa y redirigir
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Auto-redirigir a la pantalla correcta
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _redirectToCorrectPlatform();
          }
        });
      }
    }
  }

  void _redirectToCorrectPlatform() {
    if (widget.userRole == 'REPARTIDOR') {
      // Repartidor - ir a pantalla móvil
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const RepartidorMobileScreen(),
        ),
      );
    } else {
        // Administrador - ir a dashboard web
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(userRole: widget.userRole),
          ),
        );
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginSupabaseScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icono
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Título
              Text(
                'Paquetería J Alvarez',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoPrincipal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Express SVC',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoSecundario,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              if (_isLoading) ...[
                // Loading
                const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verificando acceso...',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ] else ...[
                // Contenido según el rol y plataforma
                if (widget.userRole == 'REPARTIDOR' && kIsWeb) ...[
                  // Repartidor en Web - Mostrar mensaje de descarga
                  _buildRepartidorWebMessage(),
                ] else if (widget.userRole == 'ADMINISTRADOR' && !kIsWeb) ...[
                  // Administrador en Móvil - Mostrar mensaje de web
                  _buildAdminMobileMessage(),
                ] else ...[
                  // Acceso correcto - Continuar
                  _buildCorrectAccess(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepartidorWebMessage() {
    return Column(
      children: [
        // Icono de advertencia
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.phone_android,
            size: 40,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: 24),

        // Mensaje principal
        const Text(
          'Acceso desde Móvil Requerido',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textoPrincipal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Mensaje explicativo
        Text(
          'Hola ${widget.userName}!',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Como repartidor, necesitas usar la aplicación móvil para acceder a tus órdenes y funciones.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textoSecundario,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Botones de acción
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Aquí podrías agregar lógica para abrir la tienda de apps
                  _showDownloadInstructions();
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'Descargar App Móvil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _logout,
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminMobileMessage() {
    return Column(
      children: [
        // Icono de advertencia
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.computer,
            size: 40,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: 24),

        // Mensaje principal
        const Text(
          'Acceso desde Web Requerido',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textoPrincipal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Mensaje explicativo
        Text(
          'Hola ${widget.userName}!',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Como administrador, necesitas acceder desde una computadora o tablet para gestionar el sistema completo.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textoSecundario,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Botones de acción
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showWebAccessInstructions();
                },
                icon: const Icon(Icons.open_in_browser, color: Colors.white),
                label: const Text(
                  'Abrir en Navegador',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _logout,
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCorrectAccess() {
    return Column(
      children: [
        // Icono de éxito
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 40,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),

        // Mensaje de bienvenida
        Text(
          '¡Bienvenido ${widget.userName}!',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textoPrincipal,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        Text(
          widget.userRole == 'REPARTIDOR' 
              ? 'Acceso correcto desde móvil'
              : 'Acceso correcto desde web',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textoSecundario,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Botón para continuar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _redirectToCorrectPlatform,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'Continuar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDownloadInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descargar App Móvil'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para acceder como repartidor:'),
            SizedBox(height: 12),
            Text('1. Ve a la tienda de aplicaciones'),
            Text('2. Busca "Paquetería J Alvarez"'),
            Text('3. Descarga e instala la app'),
            Text('4. Inicia sesión con tus credenciales'),
            SizedBox(height: 12),
            Text(
              'La app móvil está optimizada para repartidores y incluye todas las funciones necesarias para gestionar tus entregas.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showWebAccessInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceder desde Web'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para acceder como administrador:'),
            SizedBox(height: 12),
            Text('1. Abre un navegador web'),
            Text('2. Ve a: landerlopez1992-cyber.github.io/paqueteria-julio'),
            Text('3. Inicia sesión con tus credenciales'),
            Text('4. Accede al panel de administración'),
            SizedBox(height: 12),
            Text(
              'El panel web incluye todas las funciones de administración: gestión de órdenes, repartidores, emisores, destinatarios y chat de soporte.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
