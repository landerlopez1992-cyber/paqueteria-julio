import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../screens/ordenes_table_screen.dart';
import '../screens/repartidores_screen.dart';
import '../screens/emisores_screen.dart';
import '../screens/destinatarios_screen.dart';
import '../screens/crear_orden_screen.dart';
import '../screens/envios_ajustes_screen.dart';
import '../screens/chat_admin_screen.dart';
import '../screens/buscar_orden_screen.dart';
import '../screens/login_supabase_screen.dart';

class SharedLayout extends StatefulWidget {
  final Widget child;
  final String currentScreen;
  
  const SharedLayout({
    super.key,
    required this.child,
    required this.currentScreen,
  });

  @override
  State<SharedLayout> createState() => _SharedLayoutState();
}

class _SharedLayoutState extends State<SharedLayout> {
  String? _userName;
  String? _userEmail;
  String? _fotoPerfilUrl;
  int _mensajesNoLeidos = 0;
  RealtimeChannel? _channelNotificaciones;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _cargarMensajesNoLeidos();
    _suscribirseANotificaciones();
  }

  @override
  void dispose() {
    _channelNotificaciones?.unsubscribe();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userData = await supabase
            .from('usuarios')
            .select()
            .eq('id', user.id)
            .single();
        
        if (mounted) {
          setState(() {
            _userName = userData['nombre'] ?? user.email?.split('@')[0] ?? 'Usuario';
            _userEmail = user.email;
            _fotoPerfilUrl = userData['foto_perfil'];
          });
        }
      }
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      final user = supabase.auth.currentUser;
      if (mounted && user != null) {
        setState(() {
          _userName = user.email?.split('@')[0] ?? 'Usuario';
          _userEmail = user.email;
          _fotoPerfilUrl = null;
        });
      }
    }
  }

  Future<void> _cargarMensajesNoLeidos() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Contar mensajes no leídos donde el admin no es el remitente
      final response = await supabase
          .from('mensajes_soporte')
          .select('id')
          .eq('leido', false)
          .neq('remitente_auth_id', user.id);

      if (mounted) {
        setState(() {
          _mensajesNoLeidos = response.length;
        });
      }
    } catch (e) {
      print('Error al cargar mensajes no leídos: $e');
    }
  }

  void _suscribirseANotificaciones() {
    _channelNotificaciones = supabase
        .channel('notificaciones_chat_admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_soporte',
          callback: (payload) {
            final user = supabase.auth.currentUser;
            if (user != null && payload.newRecord['remitente_auth_id'] != user.id) {
              _cargarMensajesNoLeidos();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'mensajes_soporte',
          callback: (payload) {
            _cargarMensajesNoLeidos();
          },
        )
        .subscribe();
  }

  Future<void> _marcarMensajesComoLeidos() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Marcar todos los mensajes no leídos como leídos (donde el admin no es el remitente)
      await supabase
          .from('mensajes_soporte')
          .update({'leido': true})
          .eq('leido', false)
          .neq('remitente_auth_id', user.id);

      // Actualizar contador
      _cargarMensajesNoLeidos();
    } catch (e) {
      print('Error al marcar mensajes como leídos: $e');
    }
  }
  
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Ajustes de Envíos',
      'icon': Icons.local_shipping,
      'route': 'envios',
    },
    {
      'title': 'Destinatarios',
      'icon': Icons.person_outline,
      'route': 'destinatarios',
    },
    {
      'title': 'Emisores',
      'icon': Icons.person,
      'route': 'emisores',
    },
    {
      'title': 'Repartidores',
      'icon': Icons.delivery_dining,
      'route': 'repartidores',
    },
    {
      'title': 'Órdenes',
      'icon': Icons.list_alt,
      'route': 'ordenes',
    },
    {
      'title': 'Crear Orden',
      'icon': Icons.add_box,
      'route': 'crear_orden',
    },
    {
      'title': 'Chat Soporte',
      'icon': Icons.chat_bubble,
      'route': 'chat_soporte',
    },
    {
      'title': 'Buscar Orden',
      'icon': Icons.search,
      'route': 'buscar_orden',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar izquierdo
          Container(
            width: 280,
            color: const Color(0xFF37474F),
            child: Column(
              children: [
                // Header del sidebar
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.dashboard,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Sistema de Paquetería',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                
                // Menú de navegación
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Sección Recursos
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'RECURSOS',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      // Items del menú
                      ..._menuItems.map((item) => _buildMenuItem(item)).toList(),
                    ],
                  ),
                ),
                
                // Botón de logout
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    onTap: _logout,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          
          // Área principal
          Expanded(
            child: Column(
              children: [
                // Header superior con foto de perfil y nombre
                Container(
                  height: 70,
                  color: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      // Foto de perfil
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _fotoPerfilUrl != null && _fotoPerfilUrl!.isNotEmpty
                              ? Image.network(
                                  _fotoPerfilUrl!,
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        _userName != null && _userName!.isNotEmpty
                                            ? _userName![0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Color(0xFFFFFFFF),
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    _userName != null && _userName!.isNotEmpty
                                        ? _userName![0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nombre del usuario
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _userName ?? 'Cargando...',
                              style: const TextStyle(
                                color: Color(0xFF2C2C2C),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (_userEmail != null)
                              Text(
                                _userEmail!,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                // Contenido principal
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isSelected = widget.currentScreen == item['route'];
    final isChatSoporte = item['route'] == 'chat_soporte';
    final showNotification = isChatSoporte && _mensajesNoLeidos > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _navigateToScreen(item['route']),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  Icon(
                    item['icon'],
                    color: Colors.white,
                    size: 20,
                  ),
                  if (showNotification)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _mensajesNoLeidos > 99 ? '99+' : _mensajesNoLeidos.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['title'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(String route) {
    // No navegar si ya estamos en la misma pantalla
    if (widget.currentScreen == route) return;
    
    // Si navegamos al chat, marcar mensajes como leídos
    if (route == 'chat_soporte') {
      _marcarMensajesComoLeidos();
    }
    
    Widget destinationScreen;
    
    switch (route) {
      case 'envios':
        destinationScreen = SharedLayout(
          currentScreen: 'envios',
          child: EnviosAjustesScreen(),
        );
        break;
      case 'destinatarios':
        destinationScreen = SharedLayout(
          currentScreen: 'destinatarios',
          child: DestinatariosScreen(),
        );
        break;
      case 'emisores':
        destinationScreen = SharedLayout(
          currentScreen: 'emisores',
          child: EmisoresScreen(),
        );
        break;
      case 'repartidores':
        destinationScreen = SharedLayout(
          currentScreen: 'repartidores',
          child: RepartidoresScreen(),
        );
        break;
      case 'ordenes':
        destinationScreen = SharedLayout(
          currentScreen: 'ordenes',
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: OrdenesTableScreen(),
          ),
        );
        break;
      case 'crear_orden':
        destinationScreen = const CrearOrdenScreen();
        break;
      case 'chat_soporte':
        destinationScreen = const ChatAdminScreen();
        break;
      case 'buscar_orden':
        destinationScreen = const BuscarOrdenScreen();
        break;
      default:
        return;
    }
    
    // Usar Navigator.pushReplacement con PageRouteBuilder para deshabilitar gestos
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destinationScreen,
        transitionDuration: Duration.zero, // Sin animación
        reverseTransitionDuration: Duration.zero, // Sin animación al retroceder
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // Sin transición
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cierre de sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      print('🚪 Cerrando sesión desde Admin...');
      await supabase.auth.signOut();
      print('✅ Sesión cerrada, navegando...');
      
      if (!mounted) return;
      
      // Usar Navigator con popUntil primero
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Luego reemplazar con login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginSupabaseScreen(),
        ),
      );
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cerrar sesión, intenta nuevamente'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }
}
