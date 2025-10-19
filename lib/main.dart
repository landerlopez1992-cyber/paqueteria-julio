import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/login_supabase_screen.dart';
// import 'screens/login_repartidor_screen.dart'; // No se usa actualmente
import 'screens/dashboard_screen.dart';
import 'screens/repartidor_mobile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase con persistencia de sesión
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  runApp(const PaqueteriaApp());
}

// Get supabase client
final supabase = Supabase.instance.client;

class PaqueteriaApp extends StatelessWidget {
  const PaqueteriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J Alvarez Express SVC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Escuchar cambios en el estado de autenticación
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadUserRole(session.user.id);
      } else {
        setState(() {
          _isAuthenticated = false;
          _userRole = '';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _checkAuthState() async {
    try {
      // Verificar si hay una sesión activa
      final session = supabase.auth.currentSession;
      
      if (session != null && session.user != null) {
        // Verificar si la sesión no ha expirado
        final now = DateTime.now();
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
        
        if (now.isBefore(expiresAt)) {
          await _loadUserRole(session.user.id);
        } else {
          // Sesión expirada, intentar refrescar
          try {
            final refreshedSession = await supabase.auth.refreshSession();
            if (refreshedSession.session != null) {
              await _loadUserRole(refreshedSession.session!.user.id);
            } else {
              setState(() {
                _isAuthenticated = false;
                _isLoading = false;
              });
            }
          } catch (refreshError) {
            setState(() {
              _isAuthenticated = false;
              _isLoading = false;
            });
          }
        }
      } else {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si hay error, mostrar login
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserRole(String userId) async {
    try {
      // Obtener el rol del usuario desde la base de datos
      final userData = await supabase
          .from('usuarios')
          .select('rol')
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _userRole = userData['rol']?.toString().toUpperCase() ?? 'REPARTIDOR';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si no encuentra por ID, intentar por email
      try {
        final user = supabase.auth.currentUser;
        if (user?.email != null) {
          final userData = await supabase
              .from('usuarios')
              .select('rol')
              .eq('email', user!.email!)
              .single();
          
          if (mounted) {
            setState(() {
              _isAuthenticated = true;
              _userRole = userData['rol']?.toString().toUpperCase() ?? 'REPARTIDOR';
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
              _isLoading = false;
            });
          }
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      // Redirigir según el rol del usuario
      if (_userRole == 'REPARTIDOR') {
        return const RepartidorMobileScreen();
      } else {
        return DashboardScreen(userRole: _userRole);
      }
    } else {
      // Mostrar login de administrador por defecto
      return const LoginSupabaseScreen();
    }
  }
}
