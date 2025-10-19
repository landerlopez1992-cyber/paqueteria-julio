import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class DetalleEmisorScreen extends StatefulWidget {
  final Map<String, dynamic> emisor;

  const DetalleEmisorScreen({super.key, required this.emisor});

  @override
  State<DetalleEmisorScreen> createState() => _DetalleEmisorScreenState();
}

class _DetalleEmisorScreenState extends State<DetalleEmisorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  late TextEditingController _empresaController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _direccionController = TextEditingController();
    _empresaController = TextEditingController();
    _loadEmisorData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  void _loadEmisorData() {
    _nombreController.text = widget.emisor['nombre'] ?? '';
    _emailController.text = widget.emisor['email'] ?? '';
    _telefonoController.text = widget.emisor['telefono'] ?? '';
    _direccionController.text = widget.emisor['direccion'] ?? '';
    _empresaController.text = widget.emisor['empresa'] ?? '';
  }

  Future<void> _updateEmisor() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty) {
      _showErrorDialog('Por favor completa los campos obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== INTENTANDO ACTUALIZAR EMISOR ===');
      print('ID: ${widget.emisor['id']}');
      print('Email: ${widget.emisor['email']}');
      print('Nombre: ${_nombreController.text.trim()}');
      print('Teléfono: ${_telefonoController.text.trim()}');
      print('Dirección: ${_direccionController.text.trim()}');
      print('Empresa: ${_empresaController.text.trim()}');

      // Actualizar usando el email como identificador
      final response = await supabase.from('emisores').update({
        'nombre': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        'empresa': _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim(),
      }).eq('email', widget.emisor['email']).select();

      print('=== RESPUESTA DE SUPABASE ===');
      print(response);
      print('=== FILAS ACTUALIZADAS: ${response.length} ===');

      // Actualizar los datos del widget con los nuevos valores
      widget.emisor['nombre'] = _nombreController.text.trim();
      widget.emisor['telefono'] = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();
      widget.emisor['direccion'] = _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim();
      widget.emisor['empresa'] = _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim();

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emisor actualizado exitosamente'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('=== ERROR AL ACTUALIZAR ===');
      print(e.toString());
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al actualizar emisor: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Emisor'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateEmisor();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto de perfil
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF1976D2),
                              child: Text(
                                widget.emisor['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'E',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    onPressed: () {
                                      // _pickImage(); // Future implementation
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Información personal
                      const Text(
                        'Información Personal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        enabled: false, // Email no editable
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      // Dirección
                      TextFormField(
                        controller: _direccionController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Empresa
                      TextFormField(
                        controller: _empresaController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Empresa',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Estadísticas
                      const Text(
                        'Estadísticas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Envíos Realizados', '12', Icons.send, Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard('Envíos Pendientes', '3', Icons.pending, Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }
}
