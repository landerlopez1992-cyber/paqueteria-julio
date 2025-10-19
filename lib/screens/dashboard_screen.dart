import 'package:flutter/material.dart';
import 'ordenes_table_screen.dart';
import 'repartidores_screen.dart';
import 'emisores_screen.dart';
import 'destinatarios_screen.dart';
import 'login_supabase_screen.dart';
import '../main.dart';
import '../widgets/shared_layout.dart';

class DashboardScreen extends StatefulWidget {
  final String userRole;
  
  const DashboardScreen({super.key, required this.userRole});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 4; // Por defecto seleccionar "Órdenes"

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'ENVIOS',
      'icon': Icons.local_shipping,
      'section': 'recursos',
    },
    {
      'title': 'Destinatarios',
      'icon': Icons.person_outline,
      'section': 'recursos',
    },
    {
      'title': 'Emisores',
      'icon': Icons.person,
      'section': 'recursos',
    },
    {
      'title': 'Repartidores',
      'icon': Icons.delivery_dining,
      'section': 'recursos',
    },
    {
      'title': 'Ordenes',
      'icon': Icons.list_alt,
      'section': 'recursos',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentScreen: _getCurrentScreenRoute(),
      child: _getSelectedContent(),
    );
  }

  String _getCurrentScreenRoute() {
    switch (_selectedIndex) {
      case 0: return 'envios';
      case 1: return 'destinatarios';
      case 2: return 'emisores';
      case 3: return 'repartidores';
      case 4: return 'ordenes';
      default: return 'ordenes';
    }
  }

  Widget _getSelectedContent() {
    switch (_selectedIndex) {
      case 0: // ENVIOS
        return const Center(
          child: Text(
            'Funcionalidad de ENVIOS en desarrollo',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
        );
      case 1: // Destinatarios
        return const DestinatariosScreen();
      case 2: // Emisores
        return const EmisoresScreen();
      case 3: // Repartidores
        return const RepartidoresScreen();
      case 4: // Órdenes
        return Container(
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
          child: const OrdenesTableScreen(),
        );
      default:
        return Container(
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
          child: const OrdenesTableScreen(),
        );
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        // Navegar de vuelta al AuthWrapper que detectará automáticamente que no hay sesión
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginSupabaseScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Manejar error si es necesario
      print('Error al cerrar sesión: $e');
    }
  }

}
