import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class DetalleRepartidorScreen extends StatefulWidget {
  final Map<String, dynamic> repartidor;

  const DetalleRepartidorScreen({super.key, required this.repartidor});

  @override
  State<DetalleRepartidorScreen> createState() => _DetalleRepartidorScreenState();
}

class _DetalleRepartidorScreenState extends State<DetalleRepartidorScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  
  List<String> _provinciasSeleccionadas = [];
  String _tipoVehiculoSeleccionado = 'moto';
  bool _isLoading = false;
  bool _isEditing = false;

  // Lista completa de provincias de Cuba
  final List<String> _provinciasCuba = [
    'Pinar del Río',
    'Artemisa',
    'La Habana',
    'Mayabeque',
    'Matanzas',
    'Cienfuegos',
    'Villa Clara',
    'Sancti Spíritus',
    'Ciego de Ávila',
    'Camagüey',
    'Las Tunas',
    'Granma',
    'Holguín',
    'Santiago de Cuba',
    'Guantánamo',
    'Isla de la Juventud'
  ];

  // Lista de tipos de vehículos
  final List<Map<String, String>> _tiposVehiculos = [
    {'value': 'moto', 'label': 'Moto', 'icon': '🏍️'},
    {'value': 'bicicleta', 'label': 'Bicicleta', 'icon': '🚲'},
    {'value': 'van', 'label': 'Van', 'icon': '🚐'},
    {'value': 'camion', 'label': 'Camión', 'icon': '🚛'},
    {'value': 'auto', 'label': 'Auto', 'icon': '🚗'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRepartidorData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _loadRepartidorData() {
    _nombreController.text = widget.repartidor['nombre'] ?? '';
    _emailController.text = widget.repartidor['email'] ?? '';
    _telefonoController.text = widget.repartidor['telefono'] ?? '';
    _direccionController.text = widget.repartidor['direccion'] ?? '';
    _tipoVehiculoSeleccionado = widget.repartidor['tipo_vehiculo'] ?? 'moto';
    
    // Cargar provincias asignadas desde la base de datos
    String provinciasString = widget.repartidor['provincias_asignadas'] ?? '';
    if (provinciasString.isNotEmpty) {
      _provinciasSeleccionadas = provinciasString.split(',').map((p) => p.trim()).toList();
    } else {
      _provinciasSeleccionadas = [];
    }
  }

  Future<void> _updateRepartidor() async {
    if (_nombreController.text.isEmpty || _emailController.text.isEmpty) {
      _showErrorDialog('Por favor completa los campos obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== INTENTANDO ACTUALIZAR REPARTIDOR ===');
      print('ID: ${widget.repartidor['id']}');
      print('Email: ${widget.repartidor['email']}');
      print('Nombre: ${_nombreController.text.trim()}');
      print('Teléfono: ${_telefonoController.text.trim()}');
      print('Dirección: ${_direccionController.text.trim()}');
      print('Provincias: ${_provinciasSeleccionadas.join(',')}');

      // Primero, verificar qué usuario existe en la BD
      final existingUser = await supabase
          .from('usuarios')
          .select('id, email, nombre')
          .eq('email', widget.repartidor['email'])
          .maybeSingle();
      
      print('=== USUARIO EXISTENTE EN BD ===');
      print(existingUser);

      if (existingUser == null) {
        throw Exception('No se encontró el usuario con email: ${widget.repartidor['email']}');
      }

          // Actualizar usando el email como identificador
          final response = await supabase.from('usuarios').update({
            'nombre': _nombreController.text.trim(),
            'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
            'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
            'provincias_asignadas': _provinciasSeleccionadas.isEmpty ? null : _provinciasSeleccionadas.join(','),
            'tipo_vehiculo': _tipoVehiculoSeleccionado,
          }).eq('email', widget.repartidor['email']).select();

      print('=== RESPUESTA DE SUPABASE ===');
      print(response);
      print('=== FILAS ACTUALIZADAS: ${response.length} ===');

          // Actualizar los datos del widget con los nuevos valores
          widget.repartidor['nombre'] = _nombreController.text.trim();
          widget.repartidor['telefono'] = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();
          widget.repartidor['direccion'] = _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim();
          widget.repartidor['provincias_asignadas'] = _provinciasSeleccionadas.isEmpty ? null : _provinciasSeleccionadas.join(',');
          widget.repartidor['tipo_vehiculo'] = _tipoVehiculoSeleccionado;

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repartidor actualizado exitosamente'),
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
      _showErrorDialog('Error al actualizar repartidor: ${e.toString()}');
    }
  }

  Future<void> _showProvinciasDialog() async {
    final List<String>? provinciasSeleccionadas = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return _ProvinciasDialog(
          provincias: _provinciasCuba,
          provinciasSeleccionadas: _provinciasSeleccionadas,
        );
      },
    );

    if (provinciasSeleccionadas != null) {
      setState(() {
        _provinciasSeleccionadas = provinciasSeleccionadas;
      });
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Éxito'),
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
        title: const Text('Detalles del Repartidor'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _updateRepartidor : () {
              setState(() {
                _isEditing = true;
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
                          backgroundColor: const Color(0xFF4CAF50),
                          child: Text(
                            widget.repartidor['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'R',
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
                                color: const Color(0xFF1976D2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: () {
                                  // TODO: Implementar selección de foto
                                  _showSuccessDialog('Funcionalidad de foto en desarrollo');
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
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    enabled: false, // Email no se puede cambiar
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

                      // Tipo de vehículo
                      Row(
                        children: [
                          const Icon(Icons.motorcycle, size: 20, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 8),
                          const Text(
                            'Método de transporte asignado a este repartidor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                        ],
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
                            value: _tipoVehiculoSeleccionado,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Color(0xFF2C2C2C),
                              fontSize: 16,
                            ),
                            items: _tiposVehiculos.map((Map<String, String> vehiculo) {
                              return DropdownMenuItem<String>(
                                value: vehiculo['value'],
                                child: Row(
                                  children: [
                                    Text(
                                      vehiculo['icon']!,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(vehiculo['label']!),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: _isEditing ? (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _tipoVehiculoSeleccionado = newValue;
                                });
                              }
                            } : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                  // Provincias asignadas
                  const Text(
                    'Provincias de Entrega',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón para seleccionar provincias
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Provincias asignadas:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            if (_isEditing)
                              TextButton.icon(
                                onPressed: _showProvinciasDialog,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Editar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF1976D2),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_provinciasSeleccionadas.isEmpty)
                          const Text(
                            'No hay provincias asignadas',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _provinciasSeleccionadas.map((provincia) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  provincia,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
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
                        child: _buildStatCard('Órdenes Entregadas', '24', Icons.check_circle, Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard('Órdenes Pendientes', '3', Icons.pending, Colors.orange),
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProvinciasDialog extends StatefulWidget {
  final List<String> provincias;
  final List<String> provinciasSeleccionadas;

  const _ProvinciasDialog({
    required this.provincias,
    required this.provinciasSeleccionadas,
  });

  @override
  State<_ProvinciasDialog> createState() => _ProvinciasDialogState();
}

class _ProvinciasDialogState extends State<_ProvinciasDialog> {
  late List<String> _selectedProvincias;

  @override
  void initState() {
    super.initState();
    _selectedProvincias = List.from(widget.provinciasSeleccionadas);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Provincias de Entrega'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.provincias.length,
          itemBuilder: (context, index) {
            final provincia = widget.provincias[index];
            final isSelected = _selectedProvincias.contains(provincia);
            
            return CheckboxListTile(
              value: isSelected,
              title: Text(provincia),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedProvincias.add(provincia);
                  } else {
                    _selectedProvincias.remove(provincia);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedProvincias),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
