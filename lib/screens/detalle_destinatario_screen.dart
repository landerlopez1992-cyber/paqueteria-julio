import 'package:flutter/material.dart';
import '../main.dart';
import '../data/municipios_cuba.dart';

class DetalleDestinatarioScreen extends StatefulWidget {
  final Map<String, dynamic> destinatario;

  const DetalleDestinatarioScreen({super.key, required this.destinatario});

  @override
  State<DetalleDestinatarioScreen> createState() => _DetalleDestinatarioScreenState();
}

class _DetalleDestinatarioScreenState extends State<DetalleDestinatarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  late TextEditingController _consejoPopularBateyController;
  late TextEditingController _empresaController;
  late TextEditingController _notasController;

  bool _isLoading = false;
  bool _isEditing = false;

  // Variables para selectores
  String _provinciaSeleccionada = '';
  String _municipioSeleccionado = '';
  List<String> _municipiosDisponibles = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _direccionController = TextEditingController();
    _consejoPopularBateyController = TextEditingController();
    _empresaController = TextEditingController();
    _notasController = TextEditingController();
    _loadDestinatarioData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _consejoPopularBateyController.dispose();
    _empresaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _loadDestinatarioData() {
    _nombreController.text = widget.destinatario['nombre'] ?? '';
    _emailController.text = widget.destinatario['email'] ?? '';
    _telefonoController.text = widget.destinatario['telefono'] ?? '';
    _direccionController.text = widget.destinatario['direccion'] ?? '';
    _consejoPopularBateyController.text = widget.destinatario['consejo_popular_batey'] ?? '';
    _empresaController.text = widget.destinatario['empresa'] ?? '';
    _notasController.text = widget.destinatario['notas'] ?? '';
    
    // Cargar provincia y municipio con validación
    _provinciaSeleccionada = widget.destinatario['provincia'] ?? '';
    _municipioSeleccionado = widget.destinatario['municipio'] ?? '';
    
    // Verificar que la provincia existe en la lista
    if (_provinciaSeleccionada.isNotEmpty && 
        !MunicipiosCuba.getProvincias().contains(_provinciaSeleccionada)) {
      _provinciaSeleccionada = '';
    }
    
    // Cargar municipios disponibles para la provincia
    _municipiosDisponibles = MunicipiosCuba.getMunicipiosPorProvincia(_provinciaSeleccionada);
    
    // Verificar que el municipio existe en la lista de municipios disponibles
    if (_municipioSeleccionado.isNotEmpty && 
        !_municipiosDisponibles.contains(_municipioSeleccionado)) {
      _municipioSeleccionado = '';
    }
  }

  Future<void> _updateDestinatario() async {
    if (_nombreController.text.isEmpty) {
      _showErrorDialog('Por favor completa el campo obligatorio (Nombre)');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== INTENTANDO ACTUALIZAR DESTINATARIO ===');
      print('ID: ${widget.destinatario['id']}');
      print('Nombre: ${_nombreController.text.trim()}');
      print('Email: ${_emailController.text.trim()}');
      print('Teléfono: ${_telefonoController.text.trim()}');
      print('Dirección: ${_direccionController.text.trim()}');
      print('Municipio: $_municipioSeleccionado');
      print('Provincia: $_provinciaSeleccionada');
      print('Consejo Popular/Batey: ${_consejoPopularBateyController.text.trim()}');
      print('Empresa: ${_empresaController.text.trim()}');
      print('Notas: ${_notasController.text.trim()}');

      // Actualizar usando el ID como identificador
      final response = await supabase.from('destinatarios').update({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        'municipio': _municipioSeleccionado,
        'provincia': _provinciaSeleccionada,
        'consejo_popular_batey': _consejoPopularBateyController.text.trim().isEmpty ? null : _consejoPopularBateyController.text.trim(),
        'empresa': _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim(),
        'notas': _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      }).eq('id', widget.destinatario['id']).select();

      print('=== RESPUESTA DE SUPABASE ===');
      print(response);
      print('=== FILAS ACTUALIZADAS: ${response.length} ===');

      // Actualizar los datos del widget con los nuevos valores
      widget.destinatario['nombre'] = _nombreController.text.trim();
      widget.destinatario['email'] = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
      widget.destinatario['telefono'] = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();
      widget.destinatario['direccion'] = _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim();
      widget.destinatario['municipio'] = _municipioSeleccionado;
      widget.destinatario['provincia'] = _provinciaSeleccionada;
      widget.destinatario['consejo_popular_batey'] = _consejoPopularBateyController.text.trim().isEmpty ? null : _consejoPopularBateyController.text.trim();
      widget.destinatario['empresa'] = _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim();
      widget.destinatario['notas'] = _notasController.text.trim().isEmpty ? null : _notasController.text.trim();

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destinatario actualizado exitosamente'),
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
      _showErrorDialog('Error al actualizar destinatario: ${e.toString()}');
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

  void _onProvinciaChanged(String? provincia) {
    setState(() {
      _provinciaSeleccionada = provincia ?? '';
      _municipioSeleccionado = ''; // Reset municipio when provincia changes
      _municipiosDisponibles = MunicipiosCuba.getMunicipiosPorProvincia(_provinciaSeleccionada);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Destinatario'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateDestinatario();
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto de perfil
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF4CAF50),
                            child: Text(
                              widget.destinatario['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'D',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                            labelText: 'Nombre completo *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
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

                        // Provincia
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Provincia',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _provinciaSeleccionada.isEmpty ? null : _provinciaSeleccionada,
                                  isExpanded: true,
                                  hint: const Text('Seleccionar provincia'),
                                  style: const TextStyle(
                                    color: Color(0xFF2C2C2C),
                                    fontSize: 16,
                                  ),
                                  items: MunicipiosCuba.getProvincias().map((String provincia) {
                                    return DropdownMenuItem<String>(
                                      value: provincia,
                                      child: Text(provincia),
                                    );
                                  }).toList(),
                                  onChanged: _isEditing ? _onProvinciaChanged : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Municipio
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Municipio',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _municipioSeleccionado.isEmpty ? null : _municipioSeleccionado,
                                  isExpanded: true,
                                  hint: const Text('Seleccionar municipio'),
                                  style: const TextStyle(
                                    color: Color(0xFF2C2C2C),
                                    fontSize: 16,
                                  ),
                                  items: _municipiosDisponibles.map((String municipio) {
                                    return DropdownMenuItem<String>(
                                      value: municipio,
                                      child: Text(municipio),
                                    );
                                  }).toList(),
                                  onChanged: _isEditing ? (String? newValue) {
                                    setState(() {
                                      _municipioSeleccionado = newValue ?? '';
                                    });
                                  } : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Consejo Popular / Batey
                        TextFormField(
                          controller: _consejoPopularBateyController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Consejo Popular / Batey',
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(),
                          ),
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
                        const SizedBox(height: 12),

                        // Notas
                        TextFormField(
                          controller: _notasController,
                          enabled: _isEditing,
                          decoration: const InputDecoration(
                            labelText: 'Notas',
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Información del registro
                        const Text(
                          'Información del Registro',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C2C2C),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF666666)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Fecha de registro:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.destinatario['created_at'] != null
                                    ? DateTime.parse(widget.destinatario['created_at'])
                                        .toLocal()
                                        .toString()
                                        .split('.')[0]
                                    : 'No disponible',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              if (widget.destinatario['updated_at'] != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.update, size: 16, color: Color(0xFF666666)),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Última actualización:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2C2C2C),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateTime.parse(widget.destinatario['updated_at'])
                                      .toLocal()
                                      .toString()
                                      .split('.')[0],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
