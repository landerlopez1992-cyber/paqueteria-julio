import 'package:flutter/material.dart';
import '../main.dart';
import 'detalle_emisor_screen.dart';

class EmisoresScreen extends StatefulWidget {
  const EmisoresScreen({super.key});

  @override
  State<EmisoresScreen> createState() => _EmisoresScreenState();
}

class _EmisoresScreenState extends State<EmisoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  
  List<Map<String, dynamic>> _emisores = [];
  List<Map<String, dynamic>> _emisoresFiltrados = [];
  bool _isLoading = false;
  bool _showCreateForm = false;
  Set<int> _selectedEmisores = {}; // IDs de emisores seleccionados
  bool _selectAll = false; // Estado del checkbox "seleccionar todos"

  @override
  void initState() {
    super.initState();
    _loadEmisores();
    _searchController.addListener(_filterEmisores);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  Future<void> _loadEmisores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('emisores')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _emisores = List<Map<String, dynamic>>.from(response);
        _emisoresFiltrados = _emisores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al cargar emisores: ${e.toString()}');
    }
  }

  void _filterEmisores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _emisoresFiltrados = _emisores;
      } else {
        _emisoresFiltrados = _emisores.where((emisor) {
          final nombre = (emisor['nombre'] ?? '').toString().toLowerCase();
          final email = (emisor['email'] ?? '').toString().toLowerCase();
          final telefono = (emisor['telefono'] ?? '').toString().toLowerCase();
          final empresa = (emisor['empresa'] ?? '').toString().toLowerCase();
          
          return nombre.contains(query) ||
                 email.contains(query) ||
                 telefono.contains(query) ||
                 empresa.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _createEmisor() async {
    if (_nombreController.text.isEmpty || 
        _emailController.text.isEmpty) {
      _showErrorDialog('Por favor completa los campos obligatorios');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.from('emisores').insert({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
        'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        'empresa': _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim(),
      });

      // Limpiar formulario
      _nombreController.clear();
      _emailController.clear();
      _telefonoController.clear();
      _direccionController.clear();
      _empresaController.clear();
      
      setState(() {
        _showCreateForm = false;
      });

      // Recargar lista
      await _loadEmisores();
      
      _showSuccessDialog('Emisor creado exitosamente');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al crear emisor: ${e.toString()}');
    }
  }

  Future<void> _deleteEmisor(String emisorId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este emisor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        await supabase.from('emisores').delete().eq('id', emisorId);
        
        await _loadEmisores();
        _showSuccessDialog('Emisor eliminado exitosamente');
      } catch (e) {
        _showErrorDialog('Error al eliminar emisor: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
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

  // Seleccionar/deseleccionar todos los emisores
  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        // Seleccionar todos los emisores filtrados
        _selectedEmisores = _emisoresFiltrados.map((e) => e['id'] as int).toSet();
      } else {
        // Deseleccionar todos
        _selectedEmisores.clear();
      }
    });
  }

  // Seleccionar/deseleccionar un emisor individual
  void _toggleSelectEmisor(int id) {
    setState(() {
      if (_selectedEmisores.contains(id)) {
        _selectedEmisores.remove(id);
        _selectAll = false;
      } else {
        _selectedEmisores.add(id);
        // Si se seleccionaron todos, marcar el checkbox general
        if (_selectedEmisores.length == _emisoresFiltrados.length) {
          _selectAll = true;
        }
      }
    });
  }

  // Eliminar emisores seleccionados
  Future<void> _deleteSelectedEmisores() async {
    if (_selectedEmisores.isEmpty) return;

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar ${_selectedEmisores.length} emisor(es)?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Eliminar todos los emisores seleccionados
      await supabase
          .from('emisores')
          .delete()
          .in_('id', _selectedEmisores.toList());

      _showSuccessDialog('${_selectedEmisores.length} emisor(es) eliminado(s) exitosamente');
      
      setState(() {
        _selectedEmisores.clear();
        _selectAll = false;
      });
      
      _loadEmisores();
    } catch (e) {
      _showErrorDialog('Error al eliminar emisores: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Gestión de Emisores',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  if (_selectedEmisores.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedEmisores.length} seleccionado(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  if (_selectedEmisores.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: _deleteSelectedEmisores,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Eliminar seleccionados'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showCreateForm = !_showCreateForm;
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(_showCreateForm ? 'Cancelar' : 'Crear Emisor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar emisores por nombre, email, teléfono o empresa...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF666666)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contador de resultados
          Text(
            '${_emisoresFiltrados.length} emisor${_emisoresFiltrados.length != 1 ? 'es' : ''} encontrado${_emisoresFiltrados.length != 1 ? 's' : ''}',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

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
                    'Crear Nuevo Emisor',
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
                          controller: _empresaController,
                          decoration: const InputDecoration(
                            labelText: 'Empresa',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
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
                        onPressed: _isLoading ? null : _createEmisor,
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
                            : const Text('Crear Emisor'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Lista de emisores en formato tabla
          Expanded(
            child: Container(
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
                  : _emisoresFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No hay emisores registrados'
                                    : 'No se encontraron emisores',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_searchController.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                  child: const Text('Limpiar búsqueda'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F5F5)),
                            columns: [
                              DataColumn(
                                label: Checkbox(
                                  value: _selectAll,
                                  onChanged: _toggleSelectAll,
                                  activeColor: const Color(0xFF4CAF50),
                                ),
                              ),
                              const DataColumn(
                                label: Text(
                                  'ID',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'NOMBRE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'EMAIL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'TELÉFONO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'EMPRESA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'DIRECCIÓN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'FECHA REGISTRO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'ACCIONES',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                            ],
                            rows: _emisoresFiltrados.asMap().entries.map((entry) {
                              final index = entry.key;
                              final emisor = entry.value;
                              final emisorId = emisor['id'] as int;
                              final fechaRegistro = emisor['created_at'] != null
                                  ? DateTime.parse(emisor['created_at'])
                                  : null;
                              
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: _selectedEmisores.contains(emisorId),
                                      onChanged: (value) => _toggleSelectEmisor(emisorId),
                                      activeColor: const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  DataCell(
                                    InkWell(
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => DetalleEmisorScreen(
                                              emisor: emisor,
                                            ),
                                          ),
                                        );
                                        _loadEmisores();
                                      },
                                      child: SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${(index + 1).toString().padLeft(3, '0')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2C2C2C),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        emisor['nombre'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF2C2C2C),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        emisor['email'] ?? 'Sin email',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF666666),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        emisor['telefono'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        emisor['empresa'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF1976D2),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        emisor['direccion'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF666666),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        fechaRegistro != null
                                            ? '${fechaRegistro.year}-${fechaRegistro.month.toString().padLeft(2, '0')}-${fechaRegistro.day.toString().padLeft(2, '0')}'
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 80,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.visibility,
                                              size: 16,
                                              color: Color(0xFF1976D2),
                                            ),
                                            onPressed: () async {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => DetalleEmisorScreen(
                                                    emisor: emisor,
                                                  ),
                                                ),
                                              );
                                              _loadEmisores();
                                            },
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                              minWidth: 24,
                                              minHeight: 24,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteEmisor(emisor['id']),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                              minWidth: 24,
                                              minHeight: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
