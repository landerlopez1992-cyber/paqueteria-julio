import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../main.dart';
import '../config/app_colors.dart';

class RepartidorPerfilScreen extends StatefulWidget {
  const RepartidorPerfilScreen({super.key});

  @override
  State<RepartidorPerfilScreen> createState() => _RepartidorPerfilScreenState();
}

class _RepartidorPerfilScreenState extends State<RepartidorPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  String? _fotoPerfilUrl;
  String? _repartidorId;
  double _salarioGanado = 0.0;
  int _ordenesEntregadas = 0;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosPerfil() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Obtener datos del repartidor
      final response = await supabase
          .from('usuarios')
          .select('*')
          .eq('id', user.id)
          .single();

      setState(() {
        _repartidorId = response['id'];
        _nombreController.text = response['nombre'] ?? '';
        _telefonoController.text = response['telefono'] ?? '';
        _emailController.text = response['email'] ?? '';
        _fotoPerfilUrl = response['foto_perfil'];
        _isLoading = false;
      });

      // Calcular salario ganado y órdenes entregadas
      await _calcularEstadisticas();
      
    } catch (e) {
      // Si no encuentra por ID, intentar por email
      final user = supabase.auth.currentUser;
      if (user?.email != null) {
        try {
          final response = await supabase
              .from('usuarios')
              .select('*')
              .eq('email', user!.email!)
              .single();

          setState(() {
            _repartidorId = response['id'];
            _nombreController.text = response['nombre'] ?? '';
            _telefonoController.text = response['telefono'] ?? '';
            _emailController.text = response['email'] ?? '';
            _fotoPerfilUrl = response['foto_perfil'];
            _isLoading = false;
          });

          await _calcularEstadisticas();
        } catch (e2) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _calcularEstadisticas() async {
    try {
      if (_repartidorId == null) return;

      // Contar órdenes entregadas
      final ordenesResponse = await supabase
          .from('ordenes')
          .select('id')
          .eq('repartidor_nombre', _nombreController.text)
          .eq('estado', 'ENTREGADO');

      setState(() {
        _ordenesEntregadas = ordenesResponse.length;
        // Calcular salario: $5 por orden entregada (puedes cambiar este valor)
        _salarioGanado = _ordenesEntregadas * 5.0;
      });
    } catch (e) {
      // print('Error al calcular estadísticas: $e');
    }
  }

  Future<void> _seleccionarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Subir imagen a Supabase Storage
        final file = File(image.path);
        final fileName = '${_repartidorId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await supabase.storage
            .from('fotos-perfil')
            .upload(fileName, file);

        // Obtener URL pública
        final publicUrl = supabase.storage
            .from('fotos-perfil')
            .getPublicUrl(fileName);

        setState(() {
          _fotoPerfilUrl = publicUrl;
        });

        // Actualizar en la base de datos
        await supabase
            .from('usuarios')
            .update({'foto_perfil': publicUrl})
            .eq('id', _repartidorId!);

        _mostrarMensaje('Foto actualizada correctamente', Colors.green);
      }
    } catch (e) {
      _mostrarMensaje('Error al actualizar foto: $e', Colors.red);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await supabase
          .from('usuarios')
          .update({
            'nombre': _nombreController.text.trim(),
            'telefono': _telefonoController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _repartidorId!);

      setState(() {
        _isEditing = false;
      });

      _mostrarMensaje('Perfil actualizado correctamente', Colors.green);
    } catch (e) {
      _mostrarMensaje('Error al actualizar perfil: $e', Colors.red);
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.header,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Foto de perfil
                    _buildFotoPerfil(),
                    const SizedBox(height: 24),

                    // Estadísticas
                    _buildEstadisticas(),
                    const SizedBox(height: 24),

                    // Información personal
                    _buildInformacionPersonal(),
                    const SizedBox(height: 24),

                    // Botones de acción
                    if (_isEditing) _buildBotonesAccion(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFotoPerfil() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4CAF50),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF4CAF50),
              backgroundImage: _fotoPerfilUrl != null
                  ? NetworkImage(_fotoPerfilUrl!)
                  : null,
              child: _fotoPerfilUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _seleccionarFoto,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Salario Ganado',
                '\$${_salarioGanado.toStringAsFixed(2)}',
                Icons.attach_money,
                const Color(0xFF4CAF50),
              ),
              _buildStatItem(
                'Órdenes Entregadas',
                _ordenesEntregadas.toString(),
                Icons.local_shipping,
                const Color(0xFF2196F3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInformacionPersonal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Personal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 16),
          
          // Nombre
          TextFormField(
            controller: _nombreController,
            enabled: _isEditing,
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: const Icon(Icons.person, color: Color(0xFF4CAF50)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Teléfono
          TextFormField(
            controller: _telefonoController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email (solo lectura)
          TextFormField(
            controller: _emailController,
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email, color: Color(0xFF666666)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _cargarDatosPerfil(); // Recargar datos originales
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF666666),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}
