import 'package:flutter/material.dart';
import '../main.dart';
import '../models/orden.dart';
import 'ordenes_table_screen.dart';
import '../widgets/shared_layout.dart';

class EditarOrdenScreen extends StatefulWidget {
  final Orden orden;

  const EditarOrdenScreen({super.key, required this.orden});

  @override
  State<EditarOrdenScreen> createState() => _EditarOrdenScreenState();
}

class _EditarOrdenScreenState extends State<EditarOrdenScreen> {
  bool _isLoading = false;
  
  // Listas de datos
  List<Map<String, dynamic>> _emisores = [];
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _repartidores = [];
  
  // Valores seleccionados
  Map<String, dynamic>? _emisorSeleccionado;
  Map<String, dynamic>? _destinatarioSeleccionado;
  DateTime? _fechaEntrega;
  bool _asignacionAutomatica = true;
  Map<String, dynamic>? _repartidorSeleccionado;
  bool _esUrgente = false;
  String _estadoSeleccionado = 'POR ENVIAR';
  
  // Variables de pago
  bool _requierePago = false;
  String _moneda = 'CUP'; // 'USD' o 'CUP'
  
  // Controllers
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _searchEmisorController = TextEditingController();
  final TextEditingController _searchDestinatarioController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _notasPagoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _inicializarValores();
  }

  void _inicializarValores() {
    _fechaEntrega = widget.orden.fechaEntrega;
    _estadoSeleccionado = widget.orden.estado;
    _esUrgente = widget.orden.esUrgente;
    _notasController.text = widget.orden.notas ?? '';
    
    // Inicializar valores de pago
    _requierePago = widget.orden.requierePago;
    _moneda = widget.orden.moneda;
    _montoController.text = widget.orden.montoCobrar > 0 ? widget.orden.montoCobrar.toString() : '';
    _notasPagoController.text = widget.orden.notasPago ?? '';
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar emisores
      final emisoresResponse = await supabase.from('emisores').select();
      _emisores = List<Map<String, dynamic>>.from(emisoresResponse);
      
      // Buscar el emisor actual
      _emisorSeleccionado = _emisores.firstWhere(
        (e) => e['nombre'] == widget.orden.emisor,
        orElse: () => {},
      );
      
      // Cargar destinatarios
      final destinatariosResponse = await supabase.from('destinatarios').select();
      _destinatarios = List<Map<String, dynamic>>.from(destinatariosResponse);
      
      // Buscar el destinatario actual
      _destinatarioSeleccionado = _destinatarios.firstWhere(
        (d) => d['nombre'] == widget.orden.receptor,
        orElse: () => {},
      );
      
      // Cargar repartidores
      final repartidoresResponse = await supabase
          .from('usuarios')
          .select('id, nombre, email, provincias_asignadas, tipo_vehiculo, rol');
      
      _repartidores = (repartidoresResponse as List<dynamic>).where((usuario) {
        final rol = usuario['rol']?.toString().toUpperCase();
        return rol == 'REPARTIDOR';
      }).cast<Map<String, dynamic>>().toList();
      
      // Buscar el repartidor actual
      if (widget.orden.repartidor != null && widget.orden.repartidor != 'Sin asignar') {
        _repartidorSeleccionado = _repartidores.firstWhere(
          (r) => r['nombre'] == widget.orden.repartidor,
          orElse: () => {},
        );
        _asignacionAutomatica = false;
      }
      
      // Cargar notas de la orden desde la base de datos
      final ordenResponse = await supabase
          .from('ordenes')
          .select('notas, es_urgente')
          .eq('id', widget.orden.id)
          .single();
      
      _notasController.text = ordenResponse['notas'] ?? '';
      _esUrgente = ordenResponse['es_urgente'] ?? false;
      
      setState(() => _isLoading = false);
    } catch (e) {
      // print('Error al cargar datos: $e');
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar datos: $e', esError: true);
    }
  }

  Future<void> _guardarCambios() async {
    // Validaciones
    if (_emisorSeleccionado == null || _emisorSeleccionado!.isEmpty) {
      _mostrarMensaje('Debe seleccionar un emisor', esError: true);
      return;
    }
    
    if (_destinatarioSeleccionado == null || _destinatarioSeleccionado!.isEmpty) {
      _mostrarMensaje('Debe seleccionar un destinatario', esError: true);
      return;
    }
    
    if (_fechaEntrega == null) {
      _mostrarMensaje('Debe seleccionar una fecha de entrega', esError: true);
      return;
    }
    
    if (!_asignacionAutomatica && _repartidorSeleccionado == null) {
      _mostrarMensaje('Debe seleccionar un repartidor', esError: true);
      return;
    }

    // Validar monto si requiere pago
    double montoCobrar = 0.0;
    if (_requierePago) {
      if (_montoController.text.trim().isEmpty) {
        _mostrarMensaje('Por favor ingresa el monto a cobrar', esError: true);
        return;
      }
      montoCobrar = double.tryParse(_montoController.text.trim()) ?? 0.0;
      if (montoCobrar <= 0) {
        _mostrarMensaje('El monto debe ser mayor a 0', esError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Determinar el repartidor a asignar
      String? repartidorNombre;
      
      if (_asignacionAutomatica) {
        // Asignar automáticamente según la provincia del destinatario
        final provinciaDestino = _destinatarioSeleccionado!['provincia'];
        
        if (provinciaDestino != null && provinciaDestino.isNotEmpty) {
          final repartidoresDisponibles = _repartidores.where((r) {
            final provincias = r['provincias_asignadas'];
            if (provincias == null) return false;
            
            if (provincias is List) {
              return provincias.contains(provinciaDestino);
            } else if (provincias is String) {
              return provincias.split(',').map((p) => p.trim()).contains(provinciaDestino);
            }
            return false;
          }).toList();
          
          if (repartidoresDisponibles.isNotEmpty) {
            repartidorNombre = repartidoresDisponibles.first['nombre'];
          }
        }
      } else {
        repartidorNombre = _repartidorSeleccionado!['nombre'];
      }

      // Actualizar la orden en Supabase
      await supabase.from('ordenes').update({
        'emisor_nombre': _emisorSeleccionado!['nombre'],
        'destinatario_nombre': _destinatarioSeleccionado!['nombre'],
        'direccion_destino': _destinatarioSeleccionado!['direccion'] ?? '',
        'fecha_entrega': _fechaEntrega!.toIso8601String(),
        'estado': _estadoSeleccionado,
        'repartidor_nombre': repartidorNombre,
        'notas': _notasController.text.trim(),
        'es_urgente': _esUrgente,
        'requiere_pago': _requierePago,
        'monto_cobrar': montoCobrar,
        'moneda': _moneda,
        'notas_pago': _notasPagoController.text.trim(),
      }).eq('id', widget.orden.id);

      if (mounted) {
        _mostrarMensaje('Orden actualizada exitosamente', esError: false);
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => SharedLayout(
                currentScreen: 'ordenes',
                child: Container(
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
                  child: OrdenesTableScreen(),
                ),
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return child;
              },
            ),
          );
        }
      }
    } catch (e) {
      // print('Error al actualizar orden: $e');
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al actualizar orden: $e', esError: true);
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? const Color(0xFFDC2626) : const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _fechaEntrega = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(
        color: Color(0xFFF5F5F5),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1976D2),
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFF2C2C2C),
                ),
                const SizedBox(width: 12),
                Text(
                  'Editar Orden #${widget.orden.numeroOrden}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
          
          // Formulario
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeccionEmisor(),
                      const SizedBox(height: 20),
                      _buildSeccionDestinatario(),
                      const SizedBox(height: 20),
                      _buildSeccionFechaEntrega(),
                      const SizedBox(height: 20),
                      _buildSeccionEstado(),
                      const SizedBox(height: 20),
                      _buildSeccionRepartidor(),
                      const SizedBox(height: 20),
                      _buildSeccionNotas(),
                      const SizedBox(height: 20),
                      _buildSeccionPago(),
                      const SizedBox(height: 20),
                      _buildSeccionUrgente(),
                      const SizedBox(height: 32),
                      _buildBotones(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionEmisor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person, color: Color(0xFF1976D2), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Emisor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_emisorSeleccionado != null && _emisorSeleccionado!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _emisorSeleccionado!['nombre'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _emisorSeleccionado = null),
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFF666666),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _searchEmisorController,
                    decoration: InputDecoration(
                      hintText: 'Buscar emisor...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF666666)),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 400,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _emisores.where((e) {
                      final searchText = _searchEmisorController.text.toLowerCase();
                      return e['nombre'].toString().toLowerCase().contains(searchText) ||
                             (e['email']?.toString().toLowerCase().contains(searchText) ?? false) ||
                             (e['telefono']?.toString().toLowerCase().contains(searchText) ?? false);
                    }).length,
                    itemBuilder: (context, index) {
                      final emisoresFiltrados = _emisores.where((e) {
                        final searchText = _searchEmisorController.text.toLowerCase();
                        return e['nombre'].toString().toLowerCase().contains(searchText) ||
                               (e['email']?.toString().toLowerCase().contains(searchText) ?? false) ||
                               (e['telefono']?.toString().toLowerCase().contains(searchText) ?? false);
                      }).toList();
                      
                      final emisor = emisoresFiltrados[index];
                      
                      return ListTile(
                        dense: true,
                        title: Text(
                          emisor['nombre'],
                          style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
                        ),
                        subtitle: Text(
                          emisor['telefono'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        ),
                        onTap: () {
                          setState(() {
                            _emisorSeleccionado = emisor;
                            _searchEmisorController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSeccionDestinatario() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Destinatario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_destinatarioSeleccionado != null && _destinatarioSeleccionado!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _destinatarioSeleccionado!['nombre'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C2C2C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _destinatarioSeleccionado = null),
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFF666666),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _searchDestinatarioController,
                    decoration: InputDecoration(
                      hintText: 'Buscar destinatario...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF666666)),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 400,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _destinatarios.where((d) {
                      final searchText = _searchDestinatarioController.text.toLowerCase();
                      return d['nombre'].toString().toLowerCase().contains(searchText) ||
                             (d['direccion']?.toString().toLowerCase().contains(searchText) ?? false) ||
                             (d['telefono']?.toString().toLowerCase().contains(searchText) ?? false);
                    }).length,
                    itemBuilder: (context, index) {
                      final destinatariosFiltrados = _destinatarios.where((d) {
                        final searchText = _searchDestinatarioController.text.toLowerCase();
                        return d['nombre'].toString().toLowerCase().contains(searchText) ||
                               (d['direccion']?.toString().toLowerCase().contains(searchText) ?? false) ||
                               (d['telefono']?.toString().toLowerCase().contains(searchText) ?? false);
                      }).toList();
                      
                      final destinatario = destinatariosFiltrados[index];
                      
                      return ListTile(
                        dense: true,
                        title: Text(
                          destinatario['nombre'],
                          style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
                        ),
                        subtitle: Text(
                          destinatario['direccion'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        ),
                        onTap: () {
                          setState(() {
                            _destinatarioSeleccionado = destinatario;
                            _searchDestinatarioController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSeccionFechaEntrega() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.calendar_today, color: Color(0xFFFF9800), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Fecha de Entrega Estimada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: InkWell(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF666666)),
                    const SizedBox(width: 12),
                    Text(
                      _fechaEntrega != null
                          ? '${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}'
                          : 'Seleccionar fecha',
                      style: TextStyle(
                        fontSize: 14,
                        color: _fechaEntrega != null ? const Color(0xFF2C2C2C) : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionEstado() {
    final estados = ['POR ENVIAR', 'EN TRANSITO', 'ENTREGADO', 'CANCELADA', 'ATRASADO'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.info, color: Color(0xFF2196F3), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Estado de la Orden',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              value: _estadoSeleccionado,
              decoration: InputDecoration(
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: estados.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(
                    estado,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _estadoSeleccionado = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionRepartidor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.delivery_dining, color: Color(0xFF9C27B0), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Asignación de Repartidor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Automático', style: TextStyle(fontSize: 14, color: Color(0xFF2C2C2C))),
            subtitle: Text(
              _asignacionAutomatica && _destinatarioSeleccionado != null
                  ? 'Provincia: ${_destinatarioSeleccionado!['provincia'] ?? 'No especificada'}'
                  : 'El sistema asignará según la provincia',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
            value: true,
            groupValue: _asignacionAutomatica,
            activeColor: const Color(0xFF1976D2),
            onChanged: (value) {
              setState(() => _asignacionAutomatica = value!);
            },
          ),
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Manual', style: TextStyle(fontSize: 14, color: Color(0xFF2C2C2C))),
            subtitle: const Text(
              'Seleccionar repartidor manualmente',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
            value: false,
            groupValue: _asignacionAutomatica,
            activeColor: const Color(0xFF1976D2),
            onChanged: (value) {
              setState(() => _asignacionAutomatica = value!);
            },
          ),
          if (!_asignacionAutomatica) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<Map<String, dynamic>>(
                value: _repartidorSeleccionado,
                decoration: InputDecoration(
                  hintText: 'Seleccionar repartidor',
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _repartidores.map((repartidor) {
                  return DropdownMenuItem(
                    value: repartidor,
                    child: Text(
                      repartidor['nombre'],
                      style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _repartidorSeleccionado = value);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionNotas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF607D8B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.note, color: Color(0xFF607D8B), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notas Adicionales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 500,
            child: TextField(
              controller: _notasController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Dejar en la puerta, llamar antes de llegar...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
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
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPago() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.payment,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información de Pago',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Requiere Pago',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            subtitle: const Text(
              'El destinatario debe pagar antes de recibir la orden',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
            value: _requierePago,
            onChanged: (value) {
              setState(() {
                _requierePago = value;
                if (!value) {
                  _montoController.clear();
                  _notasPagoController.clear();
                }
              });
            },
            activeColor: const Color(0xFF4CAF50),
            contentPadding: EdgeInsets.zero,
          ),
          if (_requierePago) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Moneda',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('CUP', style: TextStyle(fontSize: 12)),
                                value: 'CUP',
                                groupValue: _moneda,
                                onChanged: (value) {
                                  setState(() {
                                    _moneda = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('USD', style: TextStyle(fontSize: 12)),
                                value: 'USD',
                                groupValue: _moneda,
                                onChanged: (value) {
                                  setState(() {
                                    _moneda = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monto a Cobrar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _montoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.attach_money, size: 18),
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
                              borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas de Pago',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 500,
                  child: TextField(
                    controller: _notasPagoController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ej: Cobrar en efectivo, traer cambio exacto...',
                      prefixIcon: const Icon(Icons.note, size: 18),
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
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionUrgente() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orden de Urgencia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Productos que requieren control de temperatura',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _esUrgente,
            onChanged: (value) {
              setState(() => _esUrgente = value);
            },
            activeColor: const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildBotones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0E0E0),
              foregroundColor: const Color(0xFF2C2C2C),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notasController.dispose();
    _searchEmisorController.dispose();
    _searchDestinatarioController.dispose();
    _montoController.dispose();
    _notasPagoController.dispose();
    super.dispose();
  }
}

