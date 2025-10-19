import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'detalle_repartidor_screen.dart';

class RepartidoresScreen extends StatefulWidget {
  const RepartidoresScreen({super.key});

  @override
  State<RepartidoresScreen> createState() => _RepartidoresScreenState();
}

class _RepartidoresScreenState extends State<RepartidoresScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
      final TextEditingController _direccionController = TextEditingController();
      final TextEditingController _passwordController = TextEditingController();
      
      List<Map<String, dynamic>> _repartidores = [];
      List<String> _provinciasSeleccionadas = [];
      String _tipoVehiculoSeleccionado = 'moto';
      bool _isLoading = false;
      bool _showCreateForm = false;

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
    _loadRepartidores();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRepartidores() async {
    setState(() {
      _isLoading = true;
    });

        try {
          final response = await supabase
              .from('usuarios')
              .select('id, auth_id, email, nombre, rol, telefono, direccion, provincias_asignadas, tipo_vehiculo, created_at')
              .eq('rol', 'REPARTIDOR')
              .order('created_at', ascending: false);

      setState(() {
        _repartidores = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al cargar repartidores: ${e.toString()}');
    }
  }

  Future<void> _createRepartidor() async {
    if (_nombreController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      _showErrorDialog('Por favor completa todos los campos obligatorios');
      return;
    }

    if (_provinciasSeleccionadas.isEmpty) {
      _showErrorDialog('Por favor selecciona al menos una provincia de entrega');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear usuario en Supabase Auth
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user != null) {
            // Crear perfil en la tabla usuarios con provincias asignadas y tipo de vehículo
            await supabase.from('usuarios').insert({
              'auth_id': authResponse.user!.id,
              'email': _emailController.text.trim(),
              'nombre': _nombreController.text.trim(),
              'rol': 'REPARTIDOR',
              'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
              'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
              'provincias_asignadas': _provinciasSeleccionadas.join(','),
              'tipo_vehiculo': _tipoVehiculoSeleccionado,
            });

            // Limpiar formulario
            _nombreController.clear();
            _emailController.clear();
            _telefonoController.clear();
            _direccionController.clear();
            _passwordController.clear();
            _provinciasSeleccionadas.clear();
            _tipoVehiculoSeleccionado = 'moto';
        
        setState(() {
          _showCreateForm = false;
        });

        // Recargar lista
        await _loadRepartidores();
        
        _showSuccessDialog('Repartidor creado exitosamente con ${_provinciasSeleccionadas.length} provincias asignadas');
      } else {
        _showErrorDialog('Error al crear el usuario en Authentication');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al crear repartidor: ${e.toString()}');
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

  Future<void> _deleteRepartidor(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este repartidor? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Eliminar de la tabla usuarios
        await supabase.from('usuarios').delete().eq('id', userId);
        
        // Recargar lista
        await _loadRepartidores();
        
        _showSuccessDialog('Repartidor eliminado exitosamente');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error al eliminar repartidor: ${e.toString()}');
      }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getVehicleIcon(String? tipoVehiculo) {
    final vehiculo = _tiposVehiculos.firstWhere(
      (v) => v['value'] == tipoVehiculo,
      orElse: () => {'value': 'moto', 'label': 'Moto', 'icon': '🏍️'},
    );
    return vehiculo['icon']!;
  }

  String _getVehicleLabel(String? tipoVehiculo) {
    final vehiculo = _tiposVehiculos.firstWhere(
      (v) => v['value'] == tipoVehiculo,
      orElse: () => {'value': 'moto', 'label': 'Moto', 'icon': '🏍️'},
    );
    return vehiculo['label']!;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Gestión de Repartidores',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showCreateForm = !_showCreateForm;
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(_showCreateForm ? 'Cancelar' : 'Crear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Formulario de creación
              if (_showCreateForm) ...[
                Container(
                  padding: const EdgeInsets.all(24),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crear Nuevo Repartidor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _telefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Selector de tipo de vehículo
                      Row(
                        children: [
                          const Icon(Icons.motorcycle, size: 20, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 8),
                          const Text(
                            'Método de transporte asignado a este repartidor *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _tipoVehiculoSeleccionado = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                  
                  // Selector de provincias
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _provinciasSeleccionadas.isEmpty ? Colors.red : const Color(0xFFE0E0E0),
                        width: _provinciasSeleccionadas.isEmpty ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.map, size: 20, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 8),
                                Text(
                                  'Provincias de entrega *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _provinciasSeleccionadas.isEmpty ? Colors.red : const Color(0xFF2C2C2C),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _showProvinciasDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Seleccionar'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_provinciasSeleccionadas.isEmpty)
                          const Text(
                            'Selecciona las provincias donde este repartidor realizará entregas',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _provinciasSeleccionadas.map((provincia) {
                              return Chip(
                                label: Text(
                                  provincia,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF4CAF50),
                                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onDeleted: () {
                                  setState(() {
                                    _provinciasSeleccionadas.remove(provincia);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showCreateForm = false;
                          });
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createRepartidor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Crear Repartidor'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Lista de repartidores
          Container(
            height: 500, // Altura fija para evitar conflicto con SingleChildScrollView
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
            child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _repartidores.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay repartidores registrados',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _repartidores.length,
                          itemBuilder: (context, index) {
                            final repartidor = _repartidores[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  child: Text(
                                    repartidor['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'R',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  repartidor['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      repartidor['email'] ?? 'Sin email',
                                      style: const TextStyle(color: Color(0xFF666666)),
                                    ),
                                    if (repartidor['telefono'] != null)
                                      Text(
                                        repartidor['telefono'],
                                        style: const TextStyle(color: Color(0xFF666666)),
                                      ),
                                        if (repartidor['provincias_asignadas'] != null && repartidor['provincias_asignadas'].toString().isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.map, size: 12, color: Color(0xFF4CAF50)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  repartidor['provincias_asignadas'].toString().split(',').length.toString() + ' provincias',
                                                  style: const TextStyle(
                                                    color: Color(0xFF4CAF50),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (repartidor['tipo_vehiculo'] != null)
                                          Row(
                                            children: [
                                              Text(
                                                _getVehicleIcon(repartidor['tipo_vehiculo']),
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getVehicleLabel(repartidor['tipo_vehiculo']),
                                                style: const TextStyle(
                                                  color: Color(0xFF1976D2),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'view') {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => DetalleRepartidorScreen(
                                            repartidor: repartidor,
                                          ),
                                        ),
                                      );
                                    } else if (value == 'delete') {
                                      _deleteRepartidor(repartidor['id']);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, color: Color(0xFF1976D2), size: 18),
                                          SizedBox(width: 8),
                                          Text('Ver detalles', style: TextStyle(color: Color(0xFF1976D2))),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => DetalleRepartidorScreen(
                                        repartidor: repartidor,
                                      ),
                                    ),
                                  );
                                  // Recargar la lista después de volver
                                  _loadRepartidores();
                                },
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
          ),
            ],
          ),
        ),
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
          child: Text('Guardar (${_selectedProvincias.length})'),
        ),
      ],
    );
  }
}
