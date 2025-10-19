import 'package:flutter/material.dart';
import '../main.dart';
import '../models/orden.dart';
import 'repartidor_perfil_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarOrdenes);
    // Cargar datos de forma asíncrona sin bloquear el hilo principal
    Future.microtask(() async {
      await _obtenerNombreRepartidor();
      await _cargarOrdenes();
    });
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
              .select('nombre')
              .eq('id', user.id)
              .single();
          setState(() {
            _repartidorNombre = response['nombre'];
          });
        } catch (e) {
          // Si no encuentra por ID, intentar por email
          if (user.email != null) {
            try {
              final response = await supabase
                  .from('usuarios')
                  .select('nombre')
                  .eq('email', user.email!)
                  .single();
              setState(() {
                _repartidorNombre = response['nombre'];
              });
            } catch (e2) {
              // Si tampoco encuentra por email, usar el email como nombre
              setState(() {
                _repartidorNombre = user.email?.split('@')[0] ?? 'Repartidor';
              });
            }
          } else {
            // Si no hay email, usar nombre por defecto
            setState(() {
              _repartidorNombre = 'Repartidor';
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

      // Cargar solo órdenes activas por defecto (más rápido)
      final response = await supabase
          .from('ordenes')
          .select()
          .eq('repartidor_nombre', repartidorNombre)
          .inFilter('estado', ['POR ENVIAR', 'EN TRANSITO'])
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

      // print('✅ Órdenes cargadas para repartidor: ${_ordenes.length}');
    } catch (e) {
      // print('❌ Error al cargar órdenes: $e');
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
        title: Column(
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
        actions: [
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
                          padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: esUrgente ? const Color(0xFFFFEBEE) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: esUrgente 
            ? Border.all(color: const Color(0xFFDC2626), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesOrden(orden),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${orden.numeroOrden}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (esUrgente) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: Colors.white, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'URGENTE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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

              const SizedBox(height: 12),

              // Información del emisor y destinatario
              _buildInfoRow(Icons.person, 'De:', orden.emisor),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.person_outline, 'Para:', orden.receptor),
              const SizedBox(height: 6),
              _buildInfoRow(Icons.location_on, 'Dirección:', orden.direccionDestino),

              if (orden.requierePago) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Color(0xFF4CAF50), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Cobrar: ${orden.moneda == 'USD' ? '\$' : '\$'} ${orden.montoCobrar.toStringAsFixed(2)} ${orden.moneda}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Fecha de entrega
              Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFF666666), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Entrega: ${_formatearFecha(orden.fechaEntrega)}',
                    style: TextStyle(
                      color: esAtrasada ? const Color(0xFFDC2626) : const Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: esAtrasada ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              // Botones de acción
              if (orden.estado != 'ENTREGADO' && orden.estado != 'CANCELADA') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _marcarComoEntregado(orden),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Entregar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _marcarComoEnTransito(orden),
                        icon: const Icon(Icons.local_shipping, size: 18),
                        label: const Text('En Tránsito'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1976D2),
                          side: const BorderSide(color: Color(0xFF1976D2)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
        Icon(icon, color: const Color(0xFF666666), size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
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

  void _mostrarDetallesOrden(Orden orden) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetallesModal(orden),
    );
  }

  Widget _buildDetallesModal(Orden orden) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${orden.numeroOrden}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem('Emisor', orden.emisor),
                  _buildDetalleItem('Destinatario', orden.receptor),
                  _buildDetalleItem('Dirección', orden.direccionDestino),
                  _buildDetalleItem('Estado', orden.estado),
                  _buildDetalleItem('Fecha de entrega', _formatearFecha(orden.fechaEntrega)),
                  
                  if (orden.requierePago) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de Pago',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Monto: ${orden.moneda == 'USD' ? '\$' : '\$'} ${orden.montoCobrar.toStringAsFixed(2)} ${orden.moneda}'),
                          Text('Estado: ${orden.pagado ? 'Pagado' : 'Pendiente'}'),
                          if (orden.notasPago != null && orden.notasPago!.isNotEmpty)
                            Text('Notas: ${orden.notasPago}'),
                        ],
                      ),
                    ),
                  ],
                  
                  if (orden.notas != null && orden.notas!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetalleItem('Notas', orden.notas!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _marcarComoEntregado(Orden orden) async {
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
}
