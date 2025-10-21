import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../widgets/shared_layout.dart';
import 'ordenes_table_screen.dart';
import '../data/municipios_cuba.dart';

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
  final _pesoController = TextEditingController();
  final _largoController = TextEditingController();
  final _anchoController = TextEditingController();
  final _altoController = TextEditingController();

  // Variables de estado
  List<Map<String, dynamic>> _emisores = [];
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _repartidores = [];
  String? _currentTenantId; // Tenant ID del admin actual
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
    _loadCurrentTenantId();
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
    _pesoController.dispose();
    _largoController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTenantId() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        final userData = await supabase
            .from('usuarios')
            .select('tenant_id')
            .eq('auth_id', currentUser.id)
            .single();
        
        setState(() {
          _currentTenantId = userData['tenant_id'];
        });
        
        print('🏢 Tenant ID del admin actual: $_currentTenantId');
        
        // Cargar datos después de obtener el tenant_id
        _cargarDatos();
      }
    } catch (e) {
      print('❌ Error obteniendo tenant_id: $e');
      _mostrarMensaje('Error al cargar información de la empresa');
    }
  }

  Future<void> _cargarDatos() async {
    if (_currentTenantId == null) {
      print('❌ No se puede cargar datos: tenant_id es null');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('📊 Cargando datos para tenant_id: $_currentTenantId');
      
      // Cargar emisores
      final emisoresResponse = await supabase
          .from('emisores')
          .select('*')
          .eq('tenant_id', _currentTenantId!) // FILTRAR POR TENANT
          .order('nombre');
      _emisores = List<Map<String, dynamic>>.from(emisoresResponse);
      _emisoresFiltrados = _emisores;

      // Cargar destinatarios
      final destinatariosResponse = await supabase
          .from('destinatarios')
          .select('*')
          .eq('tenant_id', _currentTenantId!) // FILTRAR POR TENANT
          .order('nombre');
      _destinatarios = List<Map<String, dynamic>>.from(destinatariosResponse);
      _destinatariosFiltrados = _destinatarios;

      // Cargar repartidores con sus provincias asignadas
      final repartidoresResponse = await supabase
          .from('usuarios')
          .select('id, nombre, email, rol, provincias_asignadas, tipo_vehiculo')
          .eq('rol', 'REPARTIDOR')
          .eq('tenant_id', _currentTenantId!) // FILTRAR POR TENANT
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
      print('📦 Creando orden para tenant_id: $_currentTenantId');
      final response = await supabase.from('ordenes').insert({
        'emisor_nombre': _emisorSeleccionado!['nombre'],
        'destinatario_nombre': _destinatarioSeleccionado!['nombre'],
        'direccion_destino': _destinatarioSeleccionado!['direccion'] ?? '',
        'telefono_destinatario': _destinatarioSeleccionado!['telefono'],
        'provincia_destino': _destinatarioSeleccionado!['provincia'],
        'municipio_destino': _destinatarioSeleccionado!['municipio'],
        'consejo_popular_batey': _destinatarioSeleccionado!['consejo_popular_batey'],
        'descripcion': 'Paquete de ${_emisorSeleccionado!['nombre']} para ${_destinatarioSeleccionado!['nombre']}',
        'estado': 'POR ENVIAR',
        'fecha_creacion': DateTime.now().toIso8601String(),
        'fecha_entrega': _fechaEntrega!.toIso8601String(),
        'repartidor_nombre': repartidorNombre,
        'notas': _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        'es_urgente': _esUrgente,
        'cantidad_bultos': _cantidadBultos,
        'peso': _pesoController.text.trim().isEmpty ? null : double.tryParse(_pesoController.text.trim()),
        'largo': _largoController.text.trim().isEmpty ? null : double.tryParse(_largoController.text.trim()),
        'ancho': _anchoController.text.trim().isEmpty ? null : double.tryParse(_anchoController.text.trim()),
        'alto': _altoController.text.trim().isEmpty ? null : double.tryParse(_altoController.text.trim()),
        'creado_por_nombre': 'Administrador', // TODO: Obtener del usuario actual
        'requiere_pago': _requierePago,
        'monto_cobrar': montoCobrar,
        'moneda': _moneda,
        'pagado': false,
        'notas_pago': _notasPagoController.text.trim().isEmpty ? null : _notasPagoController.text.trim(),
        'tenant_id': _currentTenantId, // ASIGNAR TENANT_ID
      }).select('numero_orden').single();

      final numeroOrden = response['numero_orden'] ?? 'N/A';
      print('✅ Orden #$numeroOrden creada exitosamente para esta empresa');
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
    return SharedLayout(
      currentScreen: 'crear_orden',
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
              onPressed: _mostrarDialogoCrearEmisor,
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
              onPressed: _mostrarDialogoCrearDestinatario,
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
                'Detalles del Paquete',
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
            'Cantidad de Bultos',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 12),
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
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cantidadBultos > 1
                        ? () {
                            setState(() {
                              _cantidadBultos--;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Número
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cantidadBultos < 99
                        ? () {
                            setState(() {
                              _cantidadBultos++;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '$_cantidadBultos ${_cantidadBultos == 1 ? 'bulto' : 'bultos'}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Peso
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pesoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Peso (lb)',
                    hintText: 'Ej: 50',
                    prefixIcon: const Icon(Icons.scale, color: Color(0xFF1976D2)),
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
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Dimensiones
          const Text(
            'Dimensiones (cm)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _largoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Largo',
                    hintText: '0.0',
                    prefixIcon: const Icon(Icons.straighten, color: Color(0xFF1976D2), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _anchoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Ancho',
                    hintText: '0.0',
                    prefixIcon: const Icon(Icons.straighten, color: Color(0xFF1976D2), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _altoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Alto',
                    hintText: '0.0',
                    prefixIcon: const Icon(Icons.straighten, color: Color(0xFF1976D2), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                    ),
                  ),
                ),
              ),
            ],
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

  Future<void> _mostrarDialogoCrearEmisor() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final dirCtrl = TextEditingController();
    final empCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Emisor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')), 
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')), 
              TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono')), 
              TextField(controller: dirCtrl, decoration: const InputDecoration(labelText: 'Dirección')), 
              TextField(controller: empCtrl, decoration: const InputDecoration(labelText: 'Empresa (opcional)')), 
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Crear')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final inserted = await supabase.from('emisores').insert({
          'nombre': nombreCtrl.text.trim(),
          'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          'telefono': telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
          'direccion': dirCtrl.text.trim(),
          'empresa': empCtrl.text.trim().isEmpty ? null : empCtrl.text.trim(),
        }).select('*').single();

        setState(() {
          _emisores.add(inserted);
          _emisoresFiltrados = _emisores;
          _emisorSeleccionado = inserted;
        });

        _mostrarMensaje('Emisor creado y seleccionado');
      } catch (e) {
        _mostrarMensaje('Error al crear emisor: $e');
      }
    }
  }

  Future<void> _mostrarDialogoCrearDestinatario() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telDigitsCtrl = TextEditingController(); // Solo dígitos después de +53
    final dirCtrl = TextEditingController();
    final bateyCtrl = TextEditingController();
    final empCtrl = TextEditingController();

    bool isValidPhone(String digits) {
      final d = digits.replaceAll(RegExp(r'\D'), '');
      if (d.isEmpty) return false;
      if (d.startsWith('5')) {
        return d.length == 8; // Celular en Cuba: 8 dígitos y empieza con 5
      }
      return d.length >= 7 && d.length <= 8; // Fijo: 7-8 dígitos
    }

    await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String provinciaSel = '';
        String municipioSel = '';
        List<String> municipiosDisponibles = [];

        bool canCreate(String nombre, String phone, String prov, String mun) {
          return nombre.trim().isNotEmpty && isValidPhone(phone) && prov.isNotEmpty && mun.isNotEmpty;
        }

        return StatefulBuilder(
          builder: (ctx, setStateSB) => AlertDialog(
            title: const Text('Crear Destinatario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), onChanged: (_) => setStateSB(() {})), 
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress), 
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('+53', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: telDigitsCtrl,
                          decoration: InputDecoration(
                            labelText: 'Teléfono (solo dígitos)',
                            errorText: telDigitsCtrl.text.isEmpty
                                ? null
                                : (isValidPhone(telDigitsCtrl.text) ? null : 'Número inválido para Cuba'),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setStateSB(() {}),
                        ),
                      ),
                    ],
                  ), 
                  TextField(controller: dirCtrl, decoration: const InputDecoration(labelText: 'Dirección')), 
                  const SizedBox(height: 12),
                  // Selector Provincia
                  DropdownButtonFormField<String>(
                    value: provinciaSel.isEmpty ? null : provinciaSel,
                    items: MunicipiosCuba.getProvincias()
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      setStateSB(() {
                        provinciaSel = val ?? '';
                        municipiosDisponibles = provinciaSel.isEmpty
                            ? []
                            : MunicipiosCuba.getMunicipiosPorProvincia(provinciaSel);
                        municipioSel = '';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Provincia'),
                  ),
                  const SizedBox(height: 12),
                  // Selector Municipio dependiente
                  DropdownButtonFormField<String>(
                    value: municipioSel.isEmpty ? null : municipioSel,
                    items: municipiosDisponibles
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) => setStateSB(() => municipioSel = val ?? ''),
                    decoration: const InputDecoration(labelText: 'Municipio'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: bateyCtrl, decoration: const InputDecoration(labelText: 'Consejo popular/Batey (opcional)')), 
                  TextField(controller: empCtrl, decoration: const InputDecoration(labelText: 'Empresa (opcional)')), 
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: canCreate(nombreCtrl.text, telDigitsCtrl.text, provinciaSel, municipioSel)
                    ? () async {
                        try {
                          final inserted = await supabase.from('destinatarios').insert({
                            'nombre': nombreCtrl.text.trim(),
                            'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                            'telefono': '+53${telDigitsCtrl.text.trim()}',
                            'direccion': dirCtrl.text.trim(),
                            'municipio': municipioSel,
                            'provincia': provinciaSel,
                            'consejo_popular_batey': bateyCtrl.text.trim().isEmpty ? null : bateyCtrl.text.trim(),
                            'empresa': empCtrl.text.trim().isEmpty ? null : empCtrl.text.trim(),
                          }).select('*').single();

                          setState(() {
                            _destinatarios.add(inserted);
                            _destinatariosFiltrados = _destinatarios;
                            _destinatarioSeleccionado = inserted;
                          });

                          if (mounted) Navigator.of(ctx).pop(true);
                          _mostrarMensaje('Destinatario creado y seleccionado');
                        } catch (e) {
                          _mostrarMensaje('Error al crear destinatario: $e');
                        }
                      }
                    : null,
                child: const Text('Crear'),
              ),
            ],
          ),
        );
      },
    );
  }
}
