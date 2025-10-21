import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'role_redirect_screen.dart';

class LoginSupabaseScreen extends StatefulWidget {
  const LoginSupabaseScreen({super.key});

  @override
  State<LoginSupabaseScreen> createState() => _LoginSupabaseScreenState();
}

class _LoginSupabaseScreenState extends State<LoginSupabaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Autenticar con Supabase
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        try {
          // Obtener información del usuario desde la tabla usuarios
          final userData = await supabase
              .from('usuarios')
              .select()
              .eq('id', response.user!.id)
              .single();

            String userRole = userData['rol']?.toString().toUpperCase() ?? '';
            String userName = userData['nombre'] ?? 'Usuario';
            String? userEmail = userData['email'];
            
            // ✅ VALIDAR PLATAFORMA ANTES DE NAVEGAR
            if (userRole == 'REPARTIDOR' && kIsWeb) {
              // 🚫 REPARTIDOR intentando acceder desde WEB - BLOQUEADO
              await supabase.auth.signOut(); // Cerrar sesión inmediatamente
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showErrorDialog(
                  'Como repartidor, debes usar la aplicación móvil.\n\nDescarga la app desde la tienda de aplicaciones para acceder a tus órdenes.',
                  'Acceso Denegado',
                );
              }
              return;
            } else if (userRole == 'ADMINISTRADOR' && !kIsWeb) {
              // 🚫 ADMINISTRADOR intentando acceder desde MÓVIL - BLOQUEADO
              await supabase.auth.signOut(); // Cerrar sesión inmediatamente
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showErrorDialog(
                  'Como administrador, debes acceder desde un navegador web.\n\nVisita: landerlopez1992-cyber.github.io/paqueteria-julio/',
                  'Acceso Denegado',
                );
              }
              return;
            }
            
            // ✅ Plataforma correcta - Navegar a RoleRedirectScreen
            if (mounted) {
              Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => RoleRedirectScreen(
                        userRole: userRole,
                        userName: userName,
                        userEmail: userEmail,
                      ),
                    ),
                  );
                }
              });
            }
        } catch (e) {
          // Si no encuentra el usuario en la tabla usuarios, intentar buscar por email
          // print('Usuario no encontrado por ID, buscando por email...');
          
          try {
            final userEmail = response.user!.email;
            if (userEmail == null) {
              throw Exception('Email del usuario es null');
            }
            
            final userData = await supabase
                .from('usuarios')
                .select()
                .eq('email', userEmail)
                .single();

            String userRole = userData['rol']?.toString().toUpperCase() ?? '';
            String userName = userData['nombre'] ?? 'Usuario';
            
            // ✅ VALIDAR PLATAFORMA ANTES DE NAVEGAR
            if (userRole == 'REPARTIDOR' && kIsWeb) {
              // 🚫 REPARTIDOR intentando acceder desde WEB - BLOQUEADO
              await supabase.auth.signOut(); // Cerrar sesión inmediatamente
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showErrorDialog(
                  'Como repartidor, debes usar la aplicación móvil.\n\nDescarga la app desde la tienda de aplicaciones para acceder a tus órdenes.',
                  'Acceso Denegado',
                );
              }
              return;
            } else if (userRole == 'ADMINISTRADOR' && !kIsWeb) {
              // 🚫 ADMINISTRADOR intentando acceder desde MÓVIL - BLOQUEADO
              await supabase.auth.signOut(); // Cerrar sesión inmediatamente
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showErrorDialog(
                  'Como administrador, debes acceder desde un navegador web.\n\nVisita: landerlopez1992-cyber.github.io/paqueteria-julio/',
                  'Acceso Denegado',
                );
              }
              return;
            }
            
            // ✅ Plataforma correcta - Navegar a RoleRedirectScreen
            if (mounted) {
              Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => RoleRedirectScreen(
                        userRole: userRole,
                        userName: userName,
                        userEmail: userEmail,
                      ),
                    ),
                  );
                }
              });
            }
          } catch (e2) {
            // Si tampoco encuentra por email, crear el registro automáticamente
            // print('Usuario no encontrado en tabla usuarios, creando registro...');
            
            // Determinar el rol basándose en el email o patrón
            String rol = 'ADMINISTRADOR'; // Por defecto
            String email = response.user!.email ?? '';
            
            // Si el email contiene "repartidor" o "delivery" o termina con @repartidor.com, es repartidor
            if (email.toLowerCase().contains('repartidor') || 
                email.toLowerCase().contains('delivery') ||
                email.toLowerCase().endsWith('@repartidor.com')) {
              rol = 'REPARTIDOR';
            }
            
            await supabase.from('usuarios').insert({
              'id': response.user!.id,
              'nombre': response.user!.email?.split('@')[0] ?? 'Usuario',
              'email': response.user!.email,
              'rol': rol,
              'created_at': DateTime.now().toIso8601String(),
            });

            String userName = response.user!.email?.split('@')[0] ?? 'Usuario';
            String? userEmail = response.user!.email;

            // ✅ VALIDAR PLATAFORMA ANTES DE NAVEGAR
            if (rol == 'REPARTIDOR' && kIsWeb) {
              // 🚫 REPARTIDOR intentando acceder desde WEB - BLOQUEADO
              await supabase.auth.signOut(); // Cerrar sesión inmediatamente
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showErrorDialog(
                  'Como repartidor, debes usar la aplicación móvil.\n\nDescarga la app desde la tienda de aplicaciones para acceder a tus órdenes.',
                  'Acceso Denegado',
                );
              }
              return;
            } else if (rol == 'ADMINISTRADOR' && !kIsWeb) {
              // 🚫 ADMINISTRADOR intentando acceder desde MÓVIL - BLOQUEADO
              await supabase.auth.signOut(); // Cerrar sesión inmediatamente
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _showErrorDialog(
                  'Como administrador, debes acceder desde un navegador web.\n\nVisita: landerlopez1992-cyber.github.io/paqueteria-julio/',
                  'Acceso Denegado',
                );
              }
              return;
            }

            // ✅ Plataforma correcta - Navegar a RoleRedirectScreen
            if (mounted) {
              Future.microtask(() {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => RoleRedirectScreen(
                        userRole: rol,
                        userName: userName,
                        userEmail: userEmail,
                      ),
                    ),
                  );
                }
              });
            }
          }
        }
      }
    } on AuthException catch (e) {
      String errorMessage = 'Error de autenticación';
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Email o contraseña incorrectos';
      } else if (e.message.contains('Email not confirmed')) {
        errorMessage = 'Por favor confirma tu email primero';
      } else {
        errorMessage = e.message;
      }
      _showErrorDialog(errorMessage);
    } on PostgrestException catch (e) {
      _showErrorDialog('Error al obtener datos del usuario: ${e.message}');
    } catch (e) {
      _showErrorDialog('Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message, [String? title]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          title ?? 'Error de Login',
          style: TextStyle(
            color: const Color(0xFF2C2C2C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: const Color(0xFF666666),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: const Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00BCD4),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            margin: const EdgeInsets.all(20),
            child: Card(
              color: const Color(0xFFFFFFFF),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo de la empresa
                      Image.asset(
                        'assets/logo_julio.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      
                      // Título
                      Text(
                        'J Alvarez Express SVC',
                        style: TextStyle(
                          color: const Color(0xFF2C2C2C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      
                      Text(
                        'Sistema de Paquetería',
                        style: TextStyle(
                          color: const Color(0xFF666666),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      
                      // Badge de Supabase
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '⚡ Powered by Supabase',
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Campo Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF1976D2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Por favor ingresa un email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Campo Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF1976D2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF666666),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      
                      // Botón de Login
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: const Color(0xFFFFFFFF),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                                  ),
                                )
                              : Text(
                                  'INICIAR SESIÓN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
