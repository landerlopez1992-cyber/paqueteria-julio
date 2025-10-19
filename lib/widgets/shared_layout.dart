import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/ordenes_table_screen.dart';
import '../screens/repartidores_screen.dart';
import '../screens/emisores_screen.dart';
import '../screens/destinatarios_screen.dart';
import '../screens/crear_orden_screen.dart';
import '../screens/envios_ajustes_screen.dart';
import '../screens/chat_admin_screen.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
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
  
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'ENVIOS',
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
              Icon(
                item['icon'],
                color: Colors.white,
                size: 20,
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
        destinationScreen = SharedLayout(
          currentScreen: 'crear_orden',
          child: CrearOrdenScreen(),
        );
        break;
      case 'chat_soporte':
        destinationScreen = const ChatAdminScreen();
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
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginSupabaseScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }
}
