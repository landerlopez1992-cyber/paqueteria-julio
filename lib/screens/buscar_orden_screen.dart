import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../main.dart';
import '../widgets/shared_layout.dart';

class BuscarOrdenScreen extends StatefulWidget {
  const BuscarOrdenScreen({super.key});

  @override
  State<BuscarOrdenScreen> createState() => _BuscarOrdenScreenState();
}

class _BuscarOrdenScreenState extends State<BuscarOrdenScreen> {
  final _numeroOrdenController = TextEditingController();
  String? _provinciaSeleccionada;
  List<String> _provincias = [];

  @override
  void initState() {
    super.initState();
    _cargarProvincias();
  }

  @override
  void dispose() {
    _numeroOrdenController.dispose();
    super.dispose();
  }

  Future<void> _cargarProvincias() async {
    // Lista completa de provincias de Cuba
    final provinciasCuba = [
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
    
    setState(() {
      _provincias = provinciasCuba;
    });
    print('Provincias cargadas: ${_provincias.length}');
  }

  Future<void> _buscarOrdenes() async {
    if (_numeroOrdenController.text.trim().isEmpty && _provinciaSeleccionada == null) {
      _mostrarMensaje('Por favor, ingrese al menos un criterio de búsqueda');
      return;
    }

    // Mostrar pantalla de carga
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PantallaCargaBusqueda(
          numeroOrden: _numeroOrdenController.text.trim(),
          provincia: _provinciaSeleccionada,
        ),
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentScreen: 'buscar_orden',
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    const Text(
                      'Buscar Orden',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Introduzca los datos de la orden para buscar',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Formulario de búsqueda
                    Card(
                      color: const Color(0xFFFFFFFF),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campo número de orden
                            const Text(
                              'Número de Orden',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _numeroOrdenController,
                              decoration: InputDecoration(
                                hintText: 'Ej: #1001',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Campo provincia
                            const Text(
                              'Provincia del Destinatario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _provinciaSeleccionada,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              hint: const Text('Seleccione una provincia'),
                              items: _provincias.map((provincia) {
                                return DropdownMenuItem<String>(
                                  value: provincia,
                                  child: Text(provincia),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _provinciaSeleccionada = value;
                                });
                              },
                            ),
                            const SizedBox(height: 32),

                            // Botón buscar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _buscarOrdenes,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'Buscar Órdenes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Pantalla de carga con icono
class PantallaCargaBusqueda extends StatefulWidget {
  final String numeroOrden;
  final String? provincia;

  const PantallaCargaBusqueda({
    super.key,
    required this.numeroOrden,
    this.provincia,
  });

  @override
  State<PantallaCargaBusqueda> createState() => _PantallaCargaBusquedaState();
}

class _PantallaCargaBusquedaState extends State<PantallaCargaBusqueda> {
  @override
  void initState() {
    super.initState();
    _buscarOrdenes();
  }

  Future<void> _buscarOrdenes() async {
    // Mínimo 3 segundos de carga
    await Future.delayed(const Duration(seconds: 3));
    
    try {
      var query = supabase.from('ordenes').select('*');

      // Filtrar por número de orden si se proporciona
      if (widget.numeroOrden.isNotEmpty) {
        query = query.eq('numero_orden', widget.numeroOrden);
      }

      // Filtrar por provincia si se selecciona
      if (widget.provincia != null) {
        query = query.eq('provincia_destino', widget.provincia!);
      }

      final response = await query;
      final resultados = List<Map<String, dynamic>>.from(response);

      // Debug: mostrar el estado de las órdenes encontradas
      print('🔍 DEBUG - Órdenes encontradas: ${resultados.length}');
      for (var orden in resultados) {
        print('📦 Orden #${orden['numero_orden']} - Estado: ${orden['estado']}');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultadosBusquedaScreen(
              resultados: resultados,
              numeroOrden: widget.numeroOrden,
              provincia: widget.provincia,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar órdenes: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentScreen: 'buscar_orden',
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de carga animado
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              
              // Texto de carga
              const Text(
                'Buscando órdenes...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 16),
              
              // Indicador de progreso
              const SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
              ),
              const SizedBox(height: 24),
              
              // Texto informativo
              const Text(
                'Verificando datos de seguridad...',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Pantalla de resultados centrada
class ResultadosBusquedaScreen extends StatelessWidget {
  final List<Map<String, dynamic>> resultados;
  final String numeroOrden;
  final String? provincia;

  const ResultadosBusquedaScreen({
    super.key,
    required this.resultados,
    required this.numeroOrden,
    this.provincia,
  });

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentScreen: 'buscar_orden',
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF37474F),
          title: const Text(
            'Resultados de Búsqueda',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de búsqueda
                    Card(
                      color: const Color(0xFFFFFFFF),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Criterios de Búsqueda',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C2C2C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (numeroOrden.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.numbers, size: 16, color: Color(0xFF666666)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Número de Orden: $numeroOrden',
                                    style: const TextStyle(color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (provincia != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.place, size: 16, color: Color(0xFF666666)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Provincia: $provincia',
                                    style: const TextStyle(color: Color(0xFF666666)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Resultados
                    if (resultados.isEmpty) ...[
                      Card(
                        color: const Color(0xFFFFFFFF),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 64,
                                color: Color(0xFF999999),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No se encontraron órdenes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C2C2C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'No se encontraron órdenes con los criterios especificados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ...(resultados.map((orden) => _buildResultadoCard(context, orden))),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultadoCard(BuildContext context, Map<String, dynamic> orden) {
    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica de la orden
            Text(
              'Orden #${orden['numero_orden']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            // Información del emisor y destinatario
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Color(0xFF666666)),
                const SizedBox(width: 8),
                Text(
                  'Emisor: ${orden['emisor_nombre']}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Color(0xFF666666)),
                const SizedBox(width: 8),
                Text(
                  'Destinatario: ${orden['destinatario_nombre']}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 18, color: Color(0xFF666666)),
                const SizedBox(width: 8),
                Text(
                  '${orden['municipio_destino']}, ${orden['provincia_destino']}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Sistema de pasos de seguimiento
            const Text(
              'Seguimiento de la Orden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            ...(_getPasosSeguimiento(orden['estado'], orden).asMap().entries.map((entry) {
              final index = entry.key;
              final paso = entry.value;
              final isCompletado = paso['completado'] as bool;
              final isActual = paso['actual'] as bool;
              final isEspecial = paso['especial'] == true;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    // Línea conectora - SOLO para estados normales, NO para especiales
                    if (index > 0 && !isEspecial)
                      Container(
                        width: 2,
                        height: 40,
                        margin: const EdgeInsets.only(left: 11),
                        color: _getPasosSeguimiento(orden['estado'], orden)[index - 1]['completado'] 
                            ? const Color(0xFF4CAF50) 
                            : const Color(0xFFE0E0E0),
                      ),
                    
                    // Icono del paso - Iconos profesionales modernos
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isEspecial 
                            ? const Color(0xFFDC2626) // Rojo para estados especiales
                            : isCompletado 
                                ? const Color(0xFF4CAF50) // Verde para completado
                                : isActual 
                                    ? const Color(0xFFFF9800) // Naranja para actual
                                    : const Color(0xFFE0E0E0), // Gris para pendiente
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: (isCompletado || isActual || isEspecial) 
                                ? (isEspecial ? const Color(0xFFDC2626) : isCompletado ? const Color(0xFF4CAF50) : const Color(0xFFFF9800)).withOpacity(0.25)
                                : const Color(0xFFE0E0E0).withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _getIconoPaso(paso['nombre'], isCompletado, isActual, isEspecial),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Información del paso
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paso['nombre'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isActual || isEspecial ? FontWeight.bold : FontWeight.w500,
                              color: isCompletado || isActual || isEspecial 
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFF999999),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            paso['descripcion'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isCompletado || isActual || isEspecial 
                                  ? const Color(0xFF666666)
                                  : const Color(0xFFCCCCCC),
                            ),
                          ),
                          // Mostrar foto de entrega si el paso es "Entregado" y está completado
                          if (paso['nombre'] == 'Entregado' && isCompletado && orden['estado'] == 'ENTREGADO') ...[
                            const SizedBox(height: 12),
                            _buildFotoEntrega(context, orden),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPasosSeguimiento(String estado, Map<String, dynamic> orden) {
    // Debug: mostrar el estado recibido
    print('🔍 DEBUG _getPasosSeguimiento - Estado recibido: "$estado"');
    final String estadoNorm = _normalizeEstado(estado);
    print('🔍 DEBUG _getPasosSeguimiento - Estado normalizado: "$estadoNorm"');
    
    // Estados normales del flujo
    final pasosNormales = [
      {
        'nombre': 'Orden Creada',
        'descripcion': 'Recibimos su paquete',
        'completado': true,
        'actual': false,
      },
      {
        'nombre': 'En Proceso',
        'descripcion': 'Estamos procesando tu paquete pesando y empaquetando',
        'completado': false,
        'actual': false,
      },
      {
        'nombre': 'En Tránsito',
        'descripcion': 'El paquete ya salió para Cuba y está en camino a la provincia ${orden['provincia_destino'] ?? 'de destino'}',
        'completado': false,
        'actual': false,
      },
      {
        'nombre': 'En Reparto',
        'descripcion': 'Tu paquete está en buenas manos y está rumbo a las manos de ${orden['destinatario_nombre'] ?? 'su destinatario'}',
        'completado': false,
        'actual': false,
      },
      {
        'nombre': 'Entregado',
        'descripcion': 'Nuestro repartidor ${_getRepartidorNombre(orden)} ya entregó su paquete a las ${_getFechaEntrega(orden)}',
        'completado': false,
        'actual': false,
      },
    ];

    // Estados especiales - SOLO se muestran estos, sin flujo normal
    final pasosAtrasado = [
      {
        'nombre': 'En Atraso',
        'descripcion': 'Hemos tenido dificultades para entregar la orden, pero no se preocupe que estamos trabajando en hacer lo mejor posible pronto recibirá la nueva fecha de entrega este al tanto del estado de la orden',
        'completado': true,
        'actual': true,
        'especial': true, // Marcar como estado especial
      },
    ];

    final pasosCancelado = [
      {
        'nombre': 'Orden Cancelada',
        'descripcion': 'Hemos cancelado esta orden para mayor información comuníquese con nuestro número de teléfono ${_getTelefonoAgencia()}',
        'completado': true,
        'actual': true,
        'especial': true, // Marcar como estado especial
      },
    ];

    // Determinar qué pasos mostrar según el estado normalizado
    switch (estadoNorm) {
      case 'POR ENVIAR':
        // Mostrar todos los pasos, pero solo los 2 primeros activos
        pasosNormales[0]['completado'] = true;
        pasosNormales[1]['actual'] = true;
        // Los demás quedan pendientes (completado: false, actual: false)
        return pasosNormales;
        
      case 'EN TRANSITO':
        // Mostrar todos los pasos, solo En Tránsito es actual
        pasosNormales[0]['completado'] = true;
        pasosNormales[1]['completado'] = true;
        pasosNormales[2]['actual'] = true;
        // En Reparto y Entregado quedan pendientes
        return pasosNormales;
        
      case 'EN REPARTO':
        // Este estado no se usa, pero lo dejamos por si acaso
        pasosNormales[0]['completado'] = true;
        pasosNormales[1]['completado'] = true;
        pasosNormales[2]['completado'] = true;
        pasosNormales[3]['actual'] = true;
        return pasosNormales;
        
      case 'ENTREGADO':
        // Todos los pasos completados
        for (int i = 0; i < pasosNormales.length; i++) {
          pasosNormales[i]['completado'] = true;
        }
        pasosNormales[4]['actual'] = true;
        return pasosNormales;
        
      case 'ATRASADO':
        // Solo mostrar el mensaje de atraso
        return pasosAtrasado;
        
      case 'CANCELADO':
      case 'CANCELADA':
        // Solo mostrar el mensaje de cancelación
        return pasosCancelado;
        
      default:
        // Estado desconocido, mostrar flujo normal
        pasosNormales[0]['completado'] = true;
        pasosNormales[0]['actual'] = true;
        return pasosNormales;
    }
  }

  // Normaliza el texto de estado: quita acentos, trim y uppercase
  String _normalizeEstado(String? raw) {
    String s = (raw ?? '').toString().trim().toUpperCase();
    final Map<String, String> accentMap = {
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
      'Ä': 'A', 'Ë': 'E', 'Ï': 'I', 'Ö': 'O', 'Ü': 'U',
      'á': 'A', 'é': 'E', 'í': 'I', 'ó': 'O', 'ú': 'U',
      'ä': 'A', 'ë': 'E', 'ï': 'I', 'ö': 'O', 'ü': 'U',
    };
    accentMap.forEach((k, v) => s = s.replaceAll(k, v));
    // Unificar posibles variantes
    s = s.replaceAll('TRÁNSITO', 'TRANSITO');
    s = s.replaceAll(' TRANSITO', ' TRANSITO');
    s = s.replaceAll('  ', ' ');
    return s;
  }

  String _getRepartidorNombre(Map<String, dynamic> orden) {
    // Usar datos disponibles directamente de la orden
    if (orden['repartidor_nombre'] != null) {
      return orden['repartidor_nombre'];
    }
    return 'del equipo';
  }

  String _getFechaEntrega(Map<String, dynamic> orden) {
    if (orden['fecha_entrega'] != null) {
      // Formatear la fecha si está disponible
      try {
        final fecha = DateTime.parse(orden['fecha_entrega']);
        return '${fecha.day}/${fecha.month}/${fecha.year} a las ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return orden['fecha_entrega'];
      }
    }
    return 'hora de entrega';
  }

  String _getTelefonoAgencia() {
    // Número de teléfono de la agencia - puedes cambiarlo por el real
    return '+1 (305) 123-4567';
  }

  Widget _getIconoPaso(String nombrePaso, bool isCompletado, bool isActual, bool isEspecial) {
    IconData baseIcon;
    IconData? badgeIcon;

    switch (nombrePaso) {
      case 'Orden Creada':
        baseIcon = Icons.local_shipping_rounded; // Camión moderno
        break;
      case 'En Proceso':
        baseIcon = Icons.settings_suggest_rounded; // Proceso/engranaje moderno
        badgeIcon = Icons.inventory_2_rounded; // Paquete pequeño
        break;
      case 'En Tránsito':
        baseIcon = Icons.flight_takeoff_rounded; // Avión moderno
        badgeIcon = Icons.inventory_2_rounded; // Paquete colgando
        break;
      case 'En Reparto':
        baseIcon = Icons.delivery_dining_rounded; // Reparto moderno
        badgeIcon = Icons.inventory_2_rounded;
        break;
      case 'Entregado':
        baseIcon = Icons.home_rounded; // Casa destino
        badgeIcon = Icons.task_alt_rounded; // Check de entrega
        break;
      case 'En Atraso':
        baseIcon = Icons.schedule_rounded; // Retraso
        break;
      case 'Orden Cancelada':
        baseIcon = Icons.cancel_rounded; // Cancelado
        break;
      default:
        baseIcon = Icons.help_outline_rounded; // Desconocido
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          baseIcon,
          color: Colors.white,
          size: 26,
        ),
        if (badgeIcon != null)
          Positioned(
            right: 2,
            bottom: 2,
            child: Icon(
              badgeIcon,
              color: Colors.white70,
              size: 13,
            ),
          ),
      ],
    );
  }

  Widget _buildFotoEntrega(BuildContext context, Map<String, dynamic> orden) {
    final String? url = (orden['foto_entrega'] ?? orden['fotoEntrega'])?.toString();

    if (url == null || url.isEmpty) {
      return Container(
        width: 240,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.photo_camera,
              size: 40,
              color: Color(0xFF999999),
            ),
            SizedBox(height: 8),
            Text(
              'Foto de Entrega',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Aquí se mostrará la foto\nde la entrega',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _mostrarImagenAmpliada(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 240,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 240,
                  height: 160,
                  color: const Color(0xFFF5F5F5),
                  alignment: Alignment.center,
                  child: const Text(
                    'No se pudo cargar la imagen',
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _mostrarImagenAmpliada(context, url),
              icon: const Icon(Icons.zoom_in),
              label: const Text('Ampliar'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _descargarImagen(url),
              icon: const Icon(Icons.download),
              label: const Text('Descargar'),
            ),
          ],
        ),
      ],
    );
  }

  void _mostrarImagenAmpliada(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  Future<void> _descargarImagen(String url) async {
    // En web: usar ancla para descargar; en móviles: abrir en navegador/sistema
    try {
      // ignore: undefined_prefixed_name
      html.AnchorElement(href: url)
        ..download = 'foto_entrega.jpg'
        ..target = '_blank'
        ..click();
    } catch (_) {
      // Fallback: abrir URL
      // ignore: deprecated_member_use
      await launch(url);
    }
  }
}