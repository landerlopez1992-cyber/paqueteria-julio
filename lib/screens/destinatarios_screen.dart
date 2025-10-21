import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../data/municipios_cuba.dart';
import 'detalle_destinatario_screen.dart';

class DestinatariosScreen extends StatefulWidget {
  const DestinatariosScreen({super.key});

  @override
  State<DestinatariosScreen> createState() => _DestinatariosScreenState();
}

class _DestinatariosScreenState extends State<DestinatariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _consejoPopularBateyController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _destinatariosFiltrados = [];
  bool _isLoading = false;
  bool _showCreateForm = false;

  // Variables para selectores
  String _provinciaSeleccionada = '';
  String _municipioSeleccionado = '';
  List<String> _municipiosDisponibles = [];

  // Variables para selección múltiple
  Set<String> _selectedDestinatarios = {}; // IDs de destinatarios seleccionados (UUID)
  bool _selectAll = false; // Estado del checkbox "seleccionar todos"

  // Validación en vivo de teléfono Cuba
  bool _isPhoneValidLive = false;
  bool _isValidCubanPhone(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return false;
    if (d.startsWith('5')) {
      return d.length == 8; // Celular: 8 dígitos empezando con 5
    }
    return d.length >= 7 && d.length <= 8; // Fijo: 7–8
  }

  @override
  void initState() {
    super.initState();
    _loadDestinatarios();
    _searchController.addListener(_filterDestinatarios);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _consejoPopularBateyController.dispose();
    _empresaController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadDestinatarios() async {
    setState(() {
      _isLoading = true;
    });

        try {
          final response = await supabase
              .from('destinatarios')
              .select('id, nombre, email, telefono, direccion, municipio, provincia, consejo_popular_batey, empresa, notas, created_at')
              .order('created_at', ascending: false);

      setState(() {
        _destinatarios = List<Map<String, dynamic>>.from(response);
        _filterDestinatarios(); // Apply filter after loading
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al cargar destinatarios: ${e.toString()}');
    }
  }

  void _filterDestinatarios() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _destinatariosFiltrados = _destinatarios.where((destinatario) {
        final nombre = destinatario['nombre']?.toLowerCase() ?? '';
        final email = destinatario['email']?.toLowerCase() ?? '';
        final telefono = destinatario['telefono']?.toLowerCase() ?? '';
        final municipio = destinatario['municipio']?.toLowerCase() ?? '';
        final provincia = destinatario['provincia']?.toLowerCase() ?? '';
        final empresa = destinatario['empresa']?.toLowerCase() ?? '';
        return nombre.contains(query) ||
               email.contains(query) ||
               telefono.contains(query) ||
               municipio.contains(query) ||
               provincia.contains(query) ||
               empresa.contains(query);
      }).toList();
    });
  }

  Future<void> _createDestinatario() async {
    if (_nombreController.text.isEmpty) {
      _showErrorDialog('Por favor completa el campo obligatorio (Nombre)');
      return;
    }

    if (_provinciaSeleccionada.isEmpty) {
      _showErrorDialog('Por favor selecciona una provincia');
      return;
    }

    if (_municipioSeleccionado.isEmpty) {
      _showErrorDialog('Por favor selecciona un municipio');
      return;
    }

    // Validación y normalización de teléfono Cuba
    String digits = _telefonoController.text.replaceAll(RegExp(r'\D'), '');
    bool isValidPhone() {
      if (digits.isEmpty) return false;
      if (digits.startsWith('5')) {
        return digits.length == 8; // Celular: 8 dígitos empezando con 5
      }
      return digits.length >= 7 && digits.length <= 8; // Fijo: 7–8 dígitos
    }

    if (!isValidPhone()) {
      _showErrorDialog('Teléfono inválido. Para Cuba: celulares 8 dígitos iniciando en 5; fijos 7–8 dígitos.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.from('destinatarios').insert({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'telefono': '+53$digits',
        'direccion': _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        'municipio': _municipioSeleccionado,
        'provincia': _provinciaSeleccionada,
        'consejo_popular_batey': _consejoPopularBateyController.text.trim().isEmpty ? null : _consejoPopularBateyController.text.trim(),
        'empresa': _empresaController.text.trim().isEmpty ? null : _empresaController.text.trim(),
        'notas': _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      });

      // Limpiar formulario
      _resetForm();
      
      setState(() {
        _showCreateForm = false;
      });

      await _loadDestinatarios();
      _showSuccessDialog('Destinatario creado exitosamente');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al crear destinatario: ${e.toString()}');
    }
  }

  Future<void> _deleteDestinatario(String destinatarioId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este destinatario?'),
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
        await supabase.from('destinatarios').delete().eq('id', destinatarioId);
        await _loadDestinatarios();
        _showSuccessDialog('Destinatario eliminado exitosamente');
      } catch (e) {
        _showErrorDialog('Error al eliminar destinatario: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Función para seleccionar/deseleccionar todos
  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedDestinatarios = _destinatariosFiltrados.map((e) => e['id'].toString()).toSet();
      } else {
        _selectedDestinatarios.clear();
      }
    });
  }

  // Función para seleccionar/deseleccionar un destinatario individual
  void _toggleSelectDestinatario(String id) {
    setState(() {
      if (_selectedDestinatarios.contains(id)) {
        _selectedDestinatarios.remove(id);
        _selectAll = false;
      } else {
        _selectedDestinatarios.add(id);
        if (_selectedDestinatarios.length == _destinatariosFiltrados.length) {
          _selectAll = true;
        }
      }
    });
  }

  // Función para eliminar destinatarios seleccionados
  Future<void> _deleteSelectedDestinatarios() async {
    if (_selectedDestinatarios.isEmpty) {
      _showErrorDialog('No hay destinatarios seleccionados');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar ${_selectedDestinatarios.length} destinatario(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
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
        // Eliminar cada destinatario seleccionado
        for (final id in _selectedDestinatarios) {
          await supabase
              .from('destinatarios')
              .delete()
              .eq('id', id);
        }

        _selectedDestinatarios.clear();
        _selectAll = false;
        await _loadDestinatarios();
        _showSuccessDialog('Destinatarios eliminados exitosamente');
      } catch (e) {
        _showErrorDialog('Error al eliminar destinatarios: ${e.toString()}');
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

  void _onProvinciaChanged(String? provincia) {
    setState(() {
      _provinciaSeleccionada = provincia ?? '';
      _municipioSeleccionado = ''; // Reset municipio when provincia changes
      _municipiosDisponibles = MunicipiosCuba.getMunicipiosPorProvincia(_provinciaSeleccionada);
    });
  }

  void _resetForm() {
    _nombreController.clear();
    _emailController.clear();
    _telefonoController.clear();
    _direccionController.clear();
    _consejoPopularBateyController.clear();
    _empresaController.clear();
    _notasController.clear();
    _provinciaSeleccionada = '';
    _municipioSeleccionado = '';
    _municipiosDisponibles = [];
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
                      'Gestión de Destinatarios',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    if (_selectedDestinatarios.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedDestinatarios.length} seleccionado(s)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (_selectedDestinatarios.isNotEmpty) ...[
                      ElevatedButton.icon(
                        onPressed: _deleteSelectedDestinatarios,
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
                      label: Text(_showCreateForm ? 'Cancelar' : 'Crear Destinatario'),
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
                  hintText: 'Buscar destinatarios por nombre, email, teléfono, municipio, provincia o empresa...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF666666)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contador de resultados
            Text(
              '${_destinatariosFiltrados.length} destinatario${_destinatariosFiltrados.length != 1 ? 's' : ''} encontrado${_destinatariosFiltrados.length != 1 ? 's' : ''}',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

          // Formulario de creación
          if (_showCreateForm) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text(
                    'Crear Nuevo Destinatario',
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
                        child: TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            // Chip +53 (no editable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '+53',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _telefonoController,
                                decoration: InputDecoration(
                                  labelText: 'Teléfono (solo dígitos)',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isPhoneValidLive ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isPhoneValidLive ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _isPhoneValidLive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: const Icon(Icons.phone),
                                  helperText: _telefonoController.text.isEmpty
                                      ? null
                                      : (_isPhoneValidLive ? 'Número válido para Cuba' : 'Celular: 8 dígitos inicia en 5. Fijo: 7–8 dígitos.'),
                                  helperStyle: TextStyle(
                                    color: _isPhoneValidLive ? const Color(0xFF4CAF50) : const Color(0xFF666666),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (v) => setState(() => _isPhoneValidLive = _isValidCubanPhone(v)),
                              ),
                            ),
                          ],
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
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Provincia *',
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
                                      onChanged: _onProvinciaChanged,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Municipio *',
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
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _municipioSeleccionado = newValue ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _consejoPopularBateyController,
                              decoration: const InputDecoration(
                                labelText: 'Consejo Popular / Batey',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_city),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _notasController,
                              decoration: const InputDecoration(
                                labelText: 'Notas',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                              ),
                            ),
                          ),
                        ],
                      ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _resetForm();
                          setState(() {
                            _showCreateForm = false;
                          });
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createDestinatario,
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
                            : const Text('Crear Destinatario'),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
          ),
          ],

          // Lista de destinatarios en formato tabla
          if (!_showCreateForm)
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
                  : _destinatariosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No hay destinatarios registrados'
                                    : 'No se encontraron destinatarios',
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
                                  'MUNICIPIO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'PROVINCIA',
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
                            rows: _destinatariosFiltrados.asMap().entries.map((entry) {
                              final index = entry.key;
                              final destinatario = entry.value;
                              final destinatarioId = destinatario['id'].toString(); // UUID es String
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: _selectedDestinatarios.contains(destinatarioId),
                                      onChanged: (value) => _toggleSelectDestinatario(destinatarioId),
                                      activeColor: const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
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
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        destinatario['nombre'] ?? 'Sin nombre',
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
                                        destinatario['email'] ?? '-',
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
                                      width: 120,
                                      child: Text(
                                        destinatario['telefono'] ?? '-',
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
                                      width: 120,
                                      child: Text(
                                        destinatario['municipio'] ?? '-',
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
                                      width: 120,
                                      child: Text(
                                        destinatario['provincia'] ?? '-',
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
                                      width: 120,
                                      child: Text(
                                        destinatario['empresa'] ?? '-',
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
                                        destinatario['created_at'] != null
                                            ? DateTime.parse(destinatario['created_at'])
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0]
                                            : '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, size: 16, color: Colors.blue),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => DetalleDestinatarioScreen(
                                                  destinatario: destinatario,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                          onPressed: () {
                                            _deleteDestinatario(destinatario['id']);
                                          },
                                        ),
                                      ],
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
