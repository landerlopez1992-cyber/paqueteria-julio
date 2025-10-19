import 'package:flutter/material.dart';
import '../main.dart';
import '../models/orden.dart';
import 'repartidor_perfil_screen.dart';
import 'chat_soporte_screen.dart';
import 'detalle_orden_screen.dart';
import '../config/app_colors.dart';

class RepartidorMobileScreen extends StatefulWidget {
  const RepartidorMobileScreen({super.key});

  @override
  State<RepartidorMobileScreen> createState() => _RepartidorMobileScreenState();
}

class _RepartidorMobileScreenState extends State<RepartidorMobileScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroEstado = 'ACTIVAS';
  List<Orden> _ordenes = [];
  bool _isLoading = true;
  String? _repartidorNombre;
  String? _fotoPerfilUrl;
  bool _fotoEntregaObligatoria = true; // Por defecto activado

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarOrdenes);
    // Cargar datos de forma asíncrona sin bloquear el hilo principal
    Future.microtask(() async {
      await _obtenerNombreRepartidor();
      await _cargarConfiguracionFoto();
      await _cargarOrdenes();
    });
  }

  Future<void> _cargarConfiguracionFoto() async {
    try {
      final response = await supabase
          .from('configuracion_envios')
          .select('foto_entrega_obligatoria')
          .limit(1)
          .single();
      
      if (mounted) {
        setState(() {
          _fotoEntregaObligatoria = response['foto_entrega_obligatoria'] ?? true;
        });
      }
    } catch (e) {
      print('Error al cargar configuración de foto: $e');
      // Mantener el valor por defecto
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _obtenerNombreRepartidor() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        try {
          final response = await supabase
              .from('usuarios')
              .select('nombre, foto_perfil')
              .eq('id', user.id)
              .single();
          setState(() {
            _repartidorNombre = response['nombre'];
            _fotoPerfilUrl = response['foto_perfil'];
          });
        } catch (e) {
          // Si no encuentra por ID, intentar por email
          if (user.email != null) {
            try {
              final response = await supabase
                  .from('usuarios')
                  .select('nombre, foto_perfil')
                  .eq('email', user.email!)
                  .single();
              setState(() {
                _repartidorNombre = response['nombre'];
                _fotoPerfilUrl = response['foto_perfil'];
              });
            } catch (e2) {
              // Si tampoco encuentra por email, usar el email como nombre
              setState(() {
                _repartidorNombre = user.email?.split('@')[0] ?? 'Repartidor';
                _fotoPerfilUrl = null;
              });
            }
          } else {
            // Si no hay email, usar nombre por defecto
            setState(() {
              _repartidorNombre = 'Repartidor';
              _fotoPerfilUrl = null;
            });
          }
        }
      }
    } catch (e) {
      // print('Error al obtener nombre del repartidor: $e');
    }
  }

  Future<void> _cargarOrdenes() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });

      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Obtener el nombre del repartidor (usar cache si ya lo tenemos)
      String? repartidorNombre = _repartidorNombre;
      
      if (repartidorNombre == null) {
        try {
          final repartidorResponse = await supabase
              .from('usuarios')
              .select('nombre')
              .eq('id', user.id)
              .single();
          repartidorNombre = repartidorResponse['nombre'] as String?;
        } catch (e) {
          // Si no encuentra el usuario por ID, intentar por email
          if (user.email != null) {
            try {
              final repartidorResponse = await supabase
                  .from('usuarios')
                  .select('nombre')
                  .eq('email', user.email!)
                  .single();
              repartidorNombre = repartidorResponse['nombre'] as String?;
            } catch (e2) {
              // Si tampoco encuentra por email, usar el email como nombre
              repartidorNombre = user.email?.split('@')[0] ?? 'Repartidor';
            }
          } else {
            // Si no hay email, usar nombre por defecto
            repartidorNombre = 'Repartidor';
          }
        }
      }

      if (repartidorNombre == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Cargar órdenes activas - buscar por múltiples variaciones del nombre
      final primerNombre = repartidorNombre.split(' ')[0]; // "Omar" de "Omar Jones"
      final response = await supabase
          .from('ordenes')
          .select()
          .or('repartidor_nombre.eq.$repartidorNombre,repartidor_nombre.ilike.%$primerNombre%')
          .inFilter('estado', ['POR ENVIAR', 'EN TRANSITO', 'ATRASADO'])
          .order('fecha_creacion', ascending: false)
          .limit(50); // Limitar a 50 órdenes para mejorar rendimiento

      if (mounted) {
        setState(() {
          _ordenes = (response as List)
              .map((ordenData) => Orden.fromJson(ordenData))
              .toList();
          _isLoading = false;
        });
      }

      print('✅ Órdenes cargadas para repartidor "$repartidorNombre": ${_ordenes.length}');
      print('📋 Filtro usado: repartidor_nombre = "$repartidorNombre"');
    } catch (e) {
      print('❌ Error al cargar órdenes: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarMensaje('Error al cargar órdenes: $e');
    }
  }

  void _filtrarOrdenes() {
    setState(() {
      // La lógica de filtrado se maneja en el getter _ordenesFiltradas
    });
  }

  List<Orden> get _ordenesFiltradas {
    var filtradas = _ordenes;

    // Filtrar por estado
    switch (_filtroEstado) {
      case 'ACTIVAS':
        filtradas = filtradas.where((orden) => 
            orden.estado != 'ENTREGADO' && 
            orden.estado != 'CANCELADA').toList();
        break;
      case 'ENTREGADAS':
        filtradas = filtradas.where((orden) => orden.estado == 'ENTREGADO').toList();
        break;
      case 'URGENTES':
        filtradas = filtradas.where((orden) => orden.esUrgente).toList();
        break;
      case 'ATRASADAS':
        filtradas = filtradas.where((orden) => 
            orden.estado == 'ATRASADO' || 
            (orden.fechaEntrega != null && orden.fechaEntrega!.isBefore(DateTime.now()))).toList();
        break;
    }

    // Filtrar por búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtradas = filtradas.where((orden) {
        return orden.numeroOrden.toLowerCase().contains(query) ||
               orden.emisor.toLowerCase().contains(query) ||
               orden.receptor.toLowerCase().contains(query) ||
               orden.direccionDestino.toLowerCase().contains(query);
      }).toList();
    }

    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.header,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Foto de perfil circular
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _fotoPerfilUrl != null && _fotoPerfilUrl!.isNotEmpty
                    ? Image.network(
                        _fotoPerfilUrl!,
                        width: 45,
                        height: 45,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _repartidorNombre != null && _repartidorNombre!.isNotEmpty
                                  ? _repartidorNombre![0].toUpperCase()
                                  : 'R',
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          _repartidorNombre != null && _repartidorNombre!.isNotEmpty
                              ? _repartidorNombre![0].toUpperCase()
                              : 'R',
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Nombre del repartidor
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Repartidor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_repartidorNombre != null)
                  Text(
                    _repartidorNombre!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChatSoporteScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.chat_bubble,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Chat de Soporte',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RepartidorPerfilScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Mi Perfil',
          ),
          IconButton(
            onPressed: _cargarOrdenes,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar órdenes...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
              ),
            ),
          ),

          // Filtros de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('ACTIVAS', _filtroEstado == 'ACTIVAS'),
                  const SizedBox(width: 8),
                  _buildFiltroChip('URGENTES', _filtroEstado == 'URGENTES'),
                  const SizedBox(width: 8),
                  _buildFiltroChip('ATRASADAS', _filtroEstado == 'ATRASADAS'),
                  const SizedBox(width: 8),
                  _buildFiltroChip('ENTREGADAS', _filtroEstado == 'ENTREGADAS'),
                ],
              ),
            ),
          ),

          // Contador de resultados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_ordenesFiltradas.length} órdenes encontradas',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_filtroEstado == 'URGENTES' && _ordenesFiltradas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'URGENTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de órdenes
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1976D2),
                    ),
                  )
                : _ordenesFiltradas.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _cargarOrdenes,
                        color: const Color(0xFF1976D2),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _ordenesFiltradas.length,
                          itemBuilder: (context, index) {
                            final orden = _ordenesFiltradas[index];
                            return _buildOrdenCard(orden);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay órdenes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes órdenes asignadas en este momento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenCard(Orden orden) {
    final esUrgente = orden.esUrgente;
    final esAtrasada = orden.fechaEntrega != null && 
                      orden.fechaEntrega!.isBefore(DateTime.now()) && 
                      orden.estado != 'ENTREGADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: esUrgente ? const Color(0xFFFFEBEE) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: esUrgente 
            ? Border.all(color: const Color(0xFFDC2626), width: 1)
            : null,
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesOrden(orden),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con número y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${orden.numeroOrden}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (esUrgente) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: Colors.white, size: 10),
                              SizedBox(width: 1),
                              Text(
                                'URGENTE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  _buildStatusChip(orden.estado, esAtrasada),
                ],
              ),

              const SizedBox(height: 8),

              // Información del emisor y destinatario
              _buildInfoRow(Icons.person, 'De:', orden.emisor),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.person_outline, 'Para:', orden.receptor),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.location_on, 'Dirección:', orden.direccionDestino),

              if (orden.requierePago) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Color(0xFF4CAF50), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Cobrar: ${orden.moneda == 'USD' ? '\$' : '\$'} ${orden.montoCobrar.toStringAsFixed(2)} ${orden.moneda}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Fecha de entrega
              Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFF666666), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Entrega: ${_formatearFecha(orden.fechaEntrega)}',
                    style: TextStyle(
                      color: esAtrasada ? const Color(0xFFDC2626) : const Color(0xFF666666),
                      fontSize: 11,
                      fontWeight: esAtrasada ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              // Botones de acción
              if (orden.estado != 'ENTREGADO' && orden.estado != 'CANCELADA') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _marcarComoEntregado(orden),
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Entregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _marcarComoEnTransito(orden),
                        icon: const Icon(Icons.local_shipping, size: 16),
                        label: const Text('En Tránsito'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                          side: const BorderSide(color: Color(0xFF1976D2)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF666666), size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 11,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String estado, bool esAtrasada) {
    final estadoReal = esAtrasada ? 'ATRASADO' : estado;
    final color = _getStatusColor(estadoReal);
    final icon = _getStatusIcon(estadoReal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            estadoReal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'ENTREGADO':
        return const Color(0xFF4CAF50);
      case 'EN TRANSITO':
        return const Color(0xFF2196F3);
      case 'POR ENVIAR':
        return const Color(0xFFFF9800);
      case 'CANCELADA':
        return const Color(0xFF9E9E9E);
      case 'ATRASADO':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getStatusIcon(String estado) {
    switch (estado) {
      case 'ENTREGADO':
        return Icons.check_circle;
      case 'EN TRANSITO':
        return Icons.local_shipping;
      case 'POR ENVIAR':
        return Icons.schedule;
      case 'CANCELADA':
        return Icons.cancel;
      case 'ATRASADO':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'No definida';
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarDetallesOrden(Orden orden) async {
    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetalleOrdenScreen(orden: orden),
      ),
    );
    
    // Si se actualizó la orden, recargar la lista
    if (resultado == true) {
      _cargarOrdenes();
    }
  }


  Future<void> _marcarComoEntregado(Orden orden) async {
    // Si la foto es obligatoria, verificar si ya tiene foto
    if (_fotoEntregaObligatoria && (orden.fotoEntrega == null || orden.fotoEntrega!.isEmpty)) {
      _mostrarErrorFotoObligatoria(orden);
      return;
    }

    // Si la orden requiere pago, verificar que se haya cobrado
    if (orden.requierePago && !orden.pagado) {
      _mostrarDialogoCobroObligatorio(orden);
      return;
    }

    final confirmado = await _mostrarConfirmacion(
      'Confirmar Entrega',
      '¿Estás seguro de que quieres marcar esta orden como entregada?',
    );
    
    if (confirmado) {
      try {
        await supabase
            .from('ordenes')
            .update({
              'estado': 'ENTREGADO',
              'fecha_entrega': DateTime.now().toIso8601String(),
            })
            .eq('id', orden.id);

        _mostrarMensaje('Orden marcada como entregada');
        _cargarOrdenes();
      } catch (e) {
        _mostrarMensaje('Error al marcar como entregada: $e');
      }
    }
  }

  Future<void> _marcarComoEnTransito(Orden orden) async {
    try {
      await supabase
          .from('ordenes')
          .update({'estado': 'EN TRANSITO'})
          .eq('id', orden.id);

      _mostrarMensaje('Orden marcada como en tránsito');
      _cargarOrdenes();
    } catch (e) {
      _mostrarMensaje('Error al marcar como en tránsito: $e');
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFF1976D2),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _mostrarConfirmacion(String titulo, String mensaje) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  void _mostrarErrorFotoObligatoria(Orden orden) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 12),
            Text(
              'Foto Obligatoria',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '❌ Error: Debes tomar una foto de la entrega primero para poder realizar la entrega exitosamente.',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _mostrarDetallesOrden(orden);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Tomar Foto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCobroObligatorio(Orden orden) {
    final monto = orden.montoCobrar;
    final moneda = orden.moneda;
    final simbolo = moneda == 'USD' ? '\$' : '\$';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.attach_money, color: Color(0xFF4CAF50), size: 24),
            SizedBox(width: 12),
            Text(
              'Cobro Obligatorio',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 El cliente debe pagar:',
              style: const TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Text(
                '$simbolo ${monto.toStringAsFixed(2)} $moneda',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '❌ Error: Debes cobrar al cliente antes de entregar la orden.',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _marcarDineroCobrado(orden);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Dinero Cobrado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _marcarDineroCobrado(Orden orden) async {
    final confirmado = await _mostrarConfirmacion(
      'Confirmar Cobro',
      '¿Confirmas que el cliente ya pagó ${orden.moneda == 'USD' ? '\$' : '\$'} ${orden.montoCobrar.toStringAsFixed(2)} ${orden.moneda}?',
    );
    
    if (confirmado) {
      try {
        await supabase
            .from('ordenes')
            .update({
              'pagado': true,
              'fecha_pago': DateTime.now().toIso8601String(),
            })
            .eq('id', orden.id);
        
        _mostrarMensaje('✅ Dinero cobrado registrado. Ahora puedes entregar la orden.');
        _cargarOrdenes();
        
      } catch (e) {
        _mostrarMensaje('Error al registrar el cobro: $e');
      }
    }
  }
}
