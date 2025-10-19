import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/shared_layout.dart';
import 'ordenes_table_screen.dart';

class CrearOrdenScreen extends StatefulWidget {
  const CrearOrdenScreen({Key? key}) : super(key: key);

  @override
  State<CrearOrdenScreen> createState() => _CrearOrdenScreenState();
}

class _CrearOrdenScreenState extends State<CrearOrdenScreen> {
  // Controladores de texto
  final _searchEmisorController = TextEditingController();
  final _searchDestinatarioController = TextEditingController();
  final _notasController = TextEditingController();
  final _montoController = TextEditingController();
  final _notasPagoController = TextEditingController();

  // Variables de estado
  List<Map<String, dynamic>> _emisores = [];
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _repartidores = [];
  List<Map<String, dynamic>> _emisoresFiltrados = [];
  List<Map<String, dynamic>> _destinatariosFiltrados = [];
  
  Map<String, dynamic>? _emisorSeleccionado;
  Map<String, dynamic>? _destinatarioSeleccionado;
  String? _repartidorSeleccionado;
  DateTime? _fechaEntrega;
  bool _esUrgente = false;
  bool _asignacionAutomatica = true;
  bool _mostrarEmisores = false;
  bool _mostrarDestinatarios = false;
  bool _isLoading = false;
  
  // Variables de pago
  bool _requierePago = false;
  String _moneda = 'CUP'; // 'USD' o 'CUP'
  
  // Cantidad de bultos
  int _cantidadBultos = 1;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _searchEmisorController.addListener(_filtrarEmisores);
    _searchDestinatarioController.addListener(_filtrarDestinatarios);
  }

  @override
  void dispose() {
    _searchEmisorController.dispose();
    _searchDestinatarioController.dispose();
    _notasController.dispose();
    _montoController.dispose();
    _notasPagoController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar emisores
      final emisoresResponse = await supabase
          .from('emisores')
          .select('*')
          .order('nombre');
      _emisores = List<Map<String, dynamic>>.from(emisoresResponse);
      _emisoresFiltrados = _emisores;

      // Cargar destinatarios
      final destinatariosResponse = await supabase
          .from('destinatarios')
          .select('*')
          .order('nombre');
      _destinatarios = List<Map<String, dynamic>>.from(destinatariosResponse);
      _destinatariosFiltrados = _destinatarios;

      // Cargar repartidores con sus provincias asignadas
      final repartidoresResponse = await supabase
          .from('usuarios')
          .select('id, nombre, email, rol, provincias_asignadas, tipo_vehiculo')
          .eq('rol', 'REPARTIDOR')
          .order('nombre');
      _repartidores = List<Map<String, dynamic>>.from(repartidoresResponse);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // print('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarMensaje('Error al cargar datos: $e');
    }
  }

  void _filtrarEmisores() {
    final query = _searchEmisorController.text.toLowerCase();
    setState(() {
      _emisoresFiltrados = _emisores.where((emisor) {
        final nombre = (emisor['nombre'] ?? '').toString().toLowerCase();
        final email = (emisor['email'] ?? '').toString().toLowerCase();
        final telefono = (emisor['telefono'] ?? '').toString().toLowerCase();
        final direccion = (emisor['direccion'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) ||
               telefono.contains(query) ||
               email.contains(query) ||
               direccion.contains(query);
      }).toList();
    });
  }

  void _filtrarDestinatarios() {
    final query = _searchDestinatarioController.text.toLowerCase();
    setState(() {
      _destinatariosFiltrados = _destinatarios.where((destinatario) {
        final nombre = (destinatario['nombre'] ?? '').toString().toLowerCase();
        final email = (destinatario['email'] ?? '').toString().toLowerCase();
        final telefono = (destinatario['telefono'] ?? '').toString().toLowerCase();
        final direccion = (destinatario['direccion'] ?? '').toString().toLowerCase();
        
        return nombre.contains(query) ||
               telefono.contains(query) ||
               email.contains(query) ||
               direccion.contains(query);
      }).toList();
    });
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() {
        _fechaEntrega = fecha;
      });
    }
  }

  String? _asignarRepartidorAutomatico() {
    // Buscar repartidores por provincia del destinatario
    if (_destinatarioSeleccionado != null && _destinatarioSeleccionado!['provincia'] != null) {
      final provinciaDestino = _destinatarioSeleccionado!['provincia'];
      
      // Filtrar repartidores que trabajen en esa provincia
      final repartidoresDisponibles = _repartidores.where((repartidor) {
        final provinciasAsignadas = repartidor['provincias_asignadas'];
        
        // Si provinciasAsignadas es null o vacío, el repartidor trabaja en todas las provincias
        if (provinciasAsignadas == null) return true;
        
        // Si es una lista, verificar si contiene la provincia
        if (provinciasAsignadas is List) {
          return provinciasAsignadas.isEmpty || provinciasAsignadas.contains(provinciaDestino);
        }
        
        // Si es un string (por alguna razón), intentar parsearlo
        if (provinciasAsignadas is String) {
          return provinciasAsignadas.isEmpty || provinciasAsignadas.contains(provinciaDestino);
        }
        
        return true;
      }).toList();
      
      if (repartidoresDisponibles.isNotEmpty) {
        return repartidoresDisponibles.first['nombre'];
      }
    }
    
    // Si no hay repartidor específico para la provincia, usar cualquier repartidor
    if (_repartidores.isNotEmpty) {
      return _repartidores.first['nombre'];
    }
    
    return null;
  }

  Future<void> _crearOrden() async {
    if (_emisorSeleccionado == null) {
      _mostrarMensaje('Por favor selecciona un emisor');
      return;
    }

    if (_destinatarioSeleccionado == null) {
      _mostrarMensaje('Por favor selecciona un destinatario');
      return;
    }

    if (_fechaEntrega == null) {
      _mostrarMensaje('Por favor selecciona una fecha de entrega');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? repartidorNombre;
      if (_asignacionAutomatica) {
        repartidorNombre = _asignarRepartidorAutomatico();
      } else {
        repartidorNombre = _repartidorSeleccionado;
      }

      // Validar monto si requiere pago
      double montoCobrar = 0.0;
      if (_requierePago) {
        if (_montoController.text.trim().isEmpty) {
          setState(() {
            _isLoading = false;
          });
          _mostrarMensaje('Por favor ingresa el monto a cobrar');
          return;
        }
        montoCobrar = double.tryParse(_montoController.text.trim()) ?? 0.0;
        if (montoCobrar <= 0) {
          setState(() {
            _isLoading = false;
          });
          _mostrarMensaje('El monto debe ser mayor a 0');
          return;
        }
      }

      // Insertar la orden (el número se generará automáticamente por el trigger)
      final response = await supabase.from('ordenes').insert({
        'emisor_nombre': _emisorSeleccionado!['nombre'],
        'destinatario_nombre': _destinatarioSeleccionado!['nombre'],
        'direccion_destino': _destinatarioSeleccionado!['direccion'] ?? '',
        'descripcion': 'Paquete de ${_emisorSeleccionado!['nombre']} para ${_destinatarioSeleccionado!['nombre']}',
        'estado': 'POR ENVIAR',
        'fecha_creacion': DateTime.now().toIso8601String(),
        'fecha_entrega': _fechaEntrega!.toIso8601String(),
        'repartidor_nombre': repartidorNombre,
        'notas': _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        'es_urgente': _esUrgente,
        'cantidad_bultos': _cantidadBultos,
        'creado_por_nombre': 'Administrador', // TODO: Obtener del usuario actual
        'requiere_pago': _requierePago,
        'monto_cobrar': montoCobrar,
        'moneda': _moneda,
        'pagado': false,
        'notas_pago': _notasPagoController.text.trim().isEmpty ? null : _notasPagoController.text.trim(),
      }).select('numero_orden').single();

      final numeroOrden = response['numero_orden'] ?? 'N/A';
      final mensaje = repartidorNombre != null 
          ? 'Orden #$numeroOrden creada exitosamente. Repartidor asignado: $repartidorNombre'
          : 'Orden #$numeroOrden creada exitosamente. Sin repartidor asignado.';
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navegar a la pantalla de órdenes después de un breve delay
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SharedLayout(
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
            ),
          );
        }
      }
      
    } catch (e) {
      _mostrarMensaje('Error al crear orden: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
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
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2C2C2C)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Crear Nueva Orden',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Formulario
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // Sección Emisor
                          _buildSeccionEmisor(),
                          const SizedBox(height: 24),
                          
                          // Sección Destinatario
                          _buildSeccionDestinatario(),
                          const SizedBox(height: 24),
                          
                          // Sección Fecha de Entrega
                          _buildSeccionFechaEntrega(),
                          const SizedBox(height: 24),
                          
                          // Sección Asignación de Repartidor
                          _buildSeccionRepartidor(),
                          const SizedBox(height: 24),
                          
                          // Sección Notas
                          _buildSeccionNotas(),
                          const SizedBox(height: 24),
                          
                          // Sección Bultos
                          _buildSeccionBultos(),
                          const SizedBox(height: 24),
                          
                          // Sección Pago
                          _buildSeccionPago(),
                          const SizedBox(height: 24),
                          
                          // Sección Orden Urgente
                          _buildSeccionUrgencia(),
                          const SizedBox(height: 32),
                          
                          // Botones
                          _buildBotones(),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionEmisor() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Emisor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Campo de búsqueda
          SizedBox(
            width: 400, // Ancho fijo más compacto
            child: TextField(
              controller: _searchEmisorController,
              decoration: InputDecoration(
                hintText: 'Buscar emisor...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onTap: () {
                setState(() {
                  _mostrarEmisores = true;
                });
              },
            ),
          ),
          
          // Emisor seleccionado
          if (_emisorSeleccionado != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _emisorSeleccionado = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          
          // Lista de emisores filtrados
          if (_mostrarEmisores && _emisoresFiltrados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _emisoresFiltrados.length,
                itemBuilder: (context, index) {
                  final emisor = _emisoresFiltrados[index];
                  return ListTile(
                    title: Text(emisor['nombre'] ?? 'Sin nombre'),
                    subtitle: Text(emisor['email'] ?? 'Sin email'),
                    onTap: () {
                      setState(() {
                        _emisorSeleccionado = emisor;
                        _mostrarEmisores = false;
                      });
                    },
                    dense: true,
                  );
                },
              ),
            ),
          ],
          
          // Botón para agregar nuevo emisor
          const SizedBox(height: 12),
          SizedBox(
            width: 200, // Ancho fijo más compacto
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a pantalla de crear emisor
                _mostrarMensaje('Funcionalidad de crear emisor en desarrollo');
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar Emisor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionDestinatario() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person_pin,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Destinatario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Campo de búsqueda
          SizedBox(
            width: 400, // Ancho fijo más compacto
            child: TextField(
              controller: _searchDestinatarioController,
              decoration: InputDecoration(
                hintText: 'Buscar destinatario...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onTap: () {
                setState(() {
                  _mostrarDestinatarios = true;
                });
              },
            ),
          ),
          
          // Destinatario seleccionado
          if (_destinatarioSeleccionado != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _destinatarioSeleccionado = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
          
          // Lista de destinatarios filtrados
          if (_mostrarDestinatarios && _destinatariosFiltrados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _destinatariosFiltrados.length,
                itemBuilder: (context, index) {
                  final destinatario = _destinatariosFiltrados[index];
                  return ListTile(
                    title: Text(destinatario['nombre'] ?? 'Sin nombre'),
                    subtitle: Text(destinatario['email'] ?? 'Sin email'),
                    onTap: () {
                      setState(() {
                        _destinatarioSeleccionado = destinatario;
                        _mostrarDestinatarios = false;
                      });
                    },
                    dense: true,
                  );
                },
              ),
            ),
          ],
          
          // Botón para agregar nuevo destinatario
          const SizedBox(height: 12),
          SizedBox(
            width: 200, // Ancho fijo más compacto
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a pantalla de crear destinatario
                _mostrarMensaje('Funcionalidad de crear destinatario en desarrollo');
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar Destinatario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionFechaEntrega() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Fecha de Entrega Estimada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: 300, // Ancho fijo más compacto
            child: InkWell(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF666666)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fechaEntrega != null
                            ? '${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}'
                            : 'Seleccionar fecha de entrega',
                        style: TextStyle(
                          fontSize: 16,
                          color: _fechaEntrega != null ? const Color(0xFF2C2C2C) : const Color(0xFF666666),
                        ),
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

  Widget _buildSeccionRepartidor() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  color: Color(0xFF9C27B0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Asignación de Repartidor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Opciones de asignación
          Column(
            children: [
              RadioListTile<bool>(
                title: const Text('Automático'),
                subtitle: Text(_destinatarioSeleccionado != null && _destinatarioSeleccionado!['provincia'] != null
                    ? 'El sistema buscará repartidores disponibles para ${_destinatarioSeleccionado!['provincia']}'
                    : 'El sistema asignará el primer repartidor disponible'),
                value: true,
                groupValue: _asignacionAutomatica,
                onChanged: (value) {
                  setState(() {
                    _asignacionAutomatica = value!;
                    if (value) {
                      _repartidorSeleccionado = null;
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<bool>(
                title: const Text('Manual'),
                subtitle: const Text('Seleccionar repartidor específico'),
                value: false,
                groupValue: _asignacionAutomatica,
                onChanged: (value) {
                  setState(() {
                    _asignacionAutomatica = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          
          // Mostrar información del repartidor que se asignaría automáticamente
          if (_asignacionAutomatica && _destinatarioSeleccionado != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1976D2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Color(0xFF1976D2), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _asignarRepartidorAutomatico() != null
                          ? 'Se asignará: ${_asignarRepartidorAutomatico()}'
                          : 'No hay repartidores disponibles para ${_destinatarioSeleccionado!['provincia']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Selector de repartidor manual
          if (!_asignacionAutomatica) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 300, // Ancho fijo más compacto
              child: DropdownButtonFormField<String>(
                value: _repartidorSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Seleccionar Repartidor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _repartidores.map((repartidor) {
                  return DropdownMenuItem<String>(
                    value: repartidor['nombre'],
                    child: Text(repartidor['nombre'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _repartidorSeleccionado = value;
                  });
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
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF607D8B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.note,
                  color: Color(0xFF607D8B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notas Adicionales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: 500, // Ancho fijo más compacto
            child: TextField(
              controller: _notasController,
              decoration: InputDecoration(
                hintText: 'Ej: Dejar en la puerta, llamar antes de entregar, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionBultos() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF1976D2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cantidad de Bultos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Cuántos bultos/paquetes incluye esta orden?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1976D2).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón -
                IconButton(
                  onPressed: _cantidadBultos > 1
                      ? () {
                          setState(() {
                            _cantidadBultos--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF1976D2),
                  iconSize: 36,
                  tooltip: 'Disminuir cantidad',
                ),
                const SizedBox(width: 24),
                // Número
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1976D2),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$_cantidadBultos',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Botón +
                IconButton(
                  onPressed: _cantidadBultos < 99
                      ? () {
                          setState(() {
                            _cantidadBultos++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF1976D2),
                  iconSize: 36,
                  tooltip: 'Aumentar cantidad',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '$_cantidadBultos ${_cantidadBultos == 1 ? 'bulto' : 'bultos'}',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1976D2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPago() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información de Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Switch para requiere pago
          SwitchListTile(
            title: const Text(
              'Requiere pago al entregar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C2C2C),
              ),
            ),
            subtitle: const Text(
              'El repartidor debe cobrar antes de marcar como entregado',
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
          
          // Mostrar campos adicionales si requiere pago
          if (_requierePago) ...[
            const SizedBox(height: 16),
            
            // Selector de moneda
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(
                      'CUP (Pesos Cubanos)',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 'CUP',
                    groupValue: _moneda,
                    onChanged: (value) {
                      setState(() {
                        _moneda = value!;
                      });
                    },
                    activeColor: const Color(0xFF4CAF50),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text(
                      'USD (Dólares)',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 'USD',
                    groupValue: _moneda,
                    onChanged: (value) {
                      setState(() {
                        _moneda = value!;
                      });
                    },
                    activeColor: const Color(0xFF4CAF50),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Campo de monto
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto a cobrar',
                hintText: 'Ej: 250.00',
                prefixIcon: Icon(
                  _moneda == 'USD' ? Icons.attach_money : Icons.monetization_on,
                  color: const Color(0xFF4CAF50),
                ),
                prefixText: _moneda == 'USD' ? '\$ ' : '\$ ',
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
                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notas del pago
            TextField(
              controller: _notasPagoController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notas sobre el pago (opcional)',
                hintText: 'Ej: Pago contra entrega, cambio disponible',
                prefixIcon: const Icon(
                  Icons.notes,
                  color: Color(0xFF4CAF50),
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
                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionUrgencia() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.priority_high,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Orden de Urgencia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Switch(
                value: _esUrgente,
                onChanged: (value) {
                  setState(() {
                    _esUrgente = value;
                  });
                },
                activeColor: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Marcar como orden urgente (productos que requieren control de temperatura)',
                  style: TextStyle(
                    fontSize: 14,
                    color: _esUrgente ? const Color(0xFFDC2626) : const Color(0xFF666666),
                    fontWeight: _esUrgente ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Selector de cantidad de bultos
          Row(
            children: [
              const Icon(
                Icons.inventory_2,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Cantidad de bultos:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C2C2C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4CAF50)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      color: const Color(0xFF4CAF50),
                      onPressed: _cantidadBultos > 1
                          ? () {
                              setState(() {
                                _cantidadBultos--;
                              });
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _cantidadBultos.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      color: const Color(0xFF4CAF50),
                      onPressed: () {
                        setState(() {
                          _cantidadBultos++;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        SizedBox(
          width: 120, // Ancho fijo más compacto
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
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
        SizedBox(
          width: 140, // Ancho fijo más compacto
          child: ElevatedButton(
            onPressed: _isLoading ? null : _crearOrden,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Crear Orden', style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }
}
