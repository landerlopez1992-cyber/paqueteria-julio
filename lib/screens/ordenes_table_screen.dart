import 'package:flutter/material.dart';
import '../models/orden.dart';
import '../main.dart';
import 'crear_orden_screen.dart';
import 'editar_orden_screen.dart';
import 'ver_orden_screen.dart';
import '../widgets/shared_layout.dart';

class OrdenesTableScreen extends StatefulWidget {
  const OrdenesTableScreen({super.key});

  @override
  State<OrdenesTableScreen> createState() => _OrdenesTableScreenState();
}

class _OrdenesTableScreenState extends State<OrdenesTableScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroEstado = 'ACTIVAS'; // 'TODAS', 'ACTIVAS', 'ENTREGADAS', 'CANCELADAS'
  Set<String> _ordenesSeleccionadas = <String>{};
  bool _seleccionarTodo = false;
  String? _accionSeleccionada;
  DateTime? _nuevaFechaEntrega;
  String? _nuevoEstado;
  String? _nuevoRepartidor;
  bool _isLoading = true;
  
  // Lista de órdenes cargadas desde Supabase
  List<Orden> _ordenes = [];
  List<Map<String, dynamic>> _repartidores = [];

  @override
  void initState() {
    super.initState();
    _cargarOrdenes();
    _cargarRepartidores();
    _searchController.addListener(() {
      setState(() {
        // Actualizar la UI cuando cambie el texto de búsqueda
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Cargar órdenes desde Supabase
  Future<void> _cargarOrdenes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Cargar órdenes con ordenamiento por defecto (sin configuración por ahora)
      // print('📋 Cargando órdenes con ordenamiento por defecto');
      
      final response = await supabase
          .from('ordenes')
          .select()
          .order('es_urgente', ascending: false)
          .order('fecha_creacion', ascending: false);

      setState(() {
        _ordenes = (response as List)
            .map((orden) => Orden.fromJson(orden))
            .toList();
        _isLoading = false;
      });

      // Verificar y actualizar órdenes atrasadas automáticamente
      await _actualizarOrdenesAtrasadas();

      // print('✅ Órdenes cargadas desde Supabase: ${_ordenes.length}');
    } catch (e) {
      // print('❌ Error al cargar órdenes: $e');
      setState(() {
        _isLoading = false;
      });
      _mostrarMensaje('Error al cargar órdenes: $e');
    }
  }

  // Actualizar automáticamente órdenes que están atrasadas
  Future<void> _actualizarOrdenesAtrasadas() async {
    try {
      final ahora = DateTime.now();
      int ordenesActualizadas = 0;

      for (Orden orden in _ordenes) {
        // Solo verificar órdenes que no estén entregadas o canceladas
        if (orden.estado != 'ENTREGADO' && 
            orden.estado != 'CANCELADA' && 
            orden.estado != 'ATRASADO' &&
            orden.fechaEntrega != null &&
            orden.fechaEntrega!.isBefore(ahora)) {
          
          // Actualizar en la base de datos
          await supabase
              .from('ordenes')
              .update({'estado': 'ATRASADO'})
              .eq('id', orden.id);
          
          // Actualizar en la lista local
          orden.estado = 'ATRASADO';
          ordenesActualizadas++;
          
          // print('Orden ${orden.id} marcada como ATRASADA (fecha: ${orden.fechaEntrega})');
        }
      }

      if (ordenesActualizadas > 0) {
        print('$ordenesActualizadas órdenes marcadas como ATRASADAS automáticamente');
        setState(() {
          // Forzar actualización de la UI
        });
      }
    } catch (e) {
      // print('Error al actualizar órdenes atrasadas: $e');
    }
  }

  // Cargar repartidores reales desde Supabase
  Future<void> _cargarRepartidores() async {
    try {
      // print('=== INICIANDO CARGA DE REPARTIDORES ===');
      final response = await supabase
          .from('usuarios')
          .select('id, nombre, email, rol');

      // print('Respuesta completa de usuarios: $response');
      // print('Tipo de respuesta: ${response.runtimeType}');

      if (response == null) {
        // print('ERROR: Respuesta es null');
        return;
      }

      // Filtrar solo repartidores
      final todosUsuarios = List<Map<String, dynamic>>.from(response as List);
      // print('Total usuarios encontrados: ${todosUsuarios.length}');
      
      // Debug: mostrar todos los usuarios y sus roles
      // for (var usuario in todosUsuarios) {
      //   print('Usuario: ${usuario['nombre']}, Rol: "${usuario['rol']}"');
      // }

      final repartidoresFiltrados = todosUsuarios
          .where((usuario) {
            final rol = usuario['rol']?.toString().toUpperCase();
            // print('Verificando rol: "$rol" == "REPARTIDOR"? ${rol == 'REPARTIDOR'}');
            return rol == 'REPARTIDOR';
          })
          .toList();

      setState(() {
        _repartidores = repartidoresFiltrados;
      });

      // print('Repartidores filtrados: ${_repartidores.length}');
      // print('Lista final de repartidores: $_repartidores');
      // print('=== FIN CARGA DE REPARTIDORES ===');
    } catch (e) {
      // print('ERROR al cargar repartidores: $e');
      // print('Stack trace: ${StackTrace.current}');
    }
  }

  // Método para verificar si una orden está atrasada
  bool _estaAtrasada(Orden orden) {
    if (orden.estado == 'ENTREGADO' || orden.estado == 'CANCELADA') {
      return false; // Ya entregadas o canceladas no están atrasadas
    }
    
    if (orden.fechaEntrega != null) {
      return DateTime.now().isAfter(orden.fechaEntrega!);
    }
    
    return false;
  }

  // Método para obtener el estado real de una orden (considerando atrasos)
  String _getEstadoReal(Orden orden) {
    if (_estaAtrasada(orden)) {
      return 'ATRASADO';
    }
    return orden.estado;
  }

  // Método para filtrar órdenes según el estado seleccionado
  List<Orden> get _ordenesFiltradas {
    List<Orden> filtradas = _ordenes;
    
    // Filtrar por estado
    switch (_filtroEstado) {
      case 'ACTIVAS':
        filtradas = filtradas.where((orden) => 
          (orden.estado == 'POR ENVIAR' || orden.estado == 'EN TRANSITO') && !_estaAtrasada(orden)).toList();
        break;
      case 'ENTREGADAS':
        filtradas = filtradas.where((orden) => orden.estado == 'ENTREGADO').toList();
        break;
      case 'CANCELADAS':
        filtradas = filtradas.where((orden) => orden.estado == 'CANCELADA').toList();
        break;
      case 'ATRASADAS':
        filtradas = filtradas.where((orden) => _estaAtrasada(orden)).toList();
        break;
      case 'URGENTES':
        filtradas = filtradas.where((orden) => orden.esUrgente).toList();
        break;
      case 'TODAS':
      default:
        // No filtrar, mostrar todas
        break;
    }
    
    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final busqueda = _searchController.text.toLowerCase();
      filtradas = filtradas.where((orden) =>
        orden.id.toLowerCase().contains(busqueda) ||
        orden.emisor.toLowerCase().contains(busqueda) ||
        orden.receptor.toLowerCase().contains(busqueda) ||
        orden.descripcion.toLowerCase().contains(busqueda) ||
        orden.direccionDestino.toLowerCase().contains(busqueda) ||
        orden.estado.toLowerCase().contains(busqueda)
      ).toList();
    }
    
    return filtradas;
  }

  // Métodos para manejar la selección
  void _toggleSeleccionarTodo() {
    setState(() {
      _seleccionarTodo = !_seleccionarTodo;
      if (_seleccionarTodo) {
        _ordenesSeleccionadas = _ordenesFiltradas.map((orden) => orden.id).toSet();
      } else {
        _ordenesSeleccionadas.clear();
      }
    });
  }

  void _toggleSeleccionOrden(String ordenId) {
    setState(() {
      if (_ordenesSeleccionadas.contains(ordenId)) {
        _ordenesSeleccionadas.remove(ordenId);
      } else {
        _ordenesSeleccionadas.add(ordenId);
      }
      
      // Actualizar el estado de "seleccionar todo"
      _seleccionarTodo = _ordenesSeleccionadas.length == _ordenesFiltradas.length;
    });
  }

  bool _isOrdenSeleccionada(String ordenId) {
    return _ordenesSeleccionadas.contains(ordenId);
  }

  // Métodos para manejar acciones en masa
  void _seleccionarAccion(String accion) {
    setState(() {
      _accionSeleccionada = accion;
      // Limpiar datos de acciones anteriores
      _nuevaFechaEntrega = null;
      _nuevoEstado = null;
      _nuevoRepartidor = null;
    });

    // Mostrar submenú según la acción seleccionada
    switch (accion) {
      case 'Cambiar fecha de entrega':
        _mostrarSelectorFecha();
        break;
      case 'Cambiar estado de orden':
        _mostrarSelectorEstado();
        break;
      case 'Cambiar repartidor asignado':
        _mostrarSelectorRepartidor();
        break;
      case 'Eliminar':
        // No necesita submenú, se ejecuta directamente
        break;
    }
  }

  void _ejecutarAccion() {
    if (_ordenesSeleccionadas.isEmpty || _accionSeleccionada == null) {
      _mostrarMensaje('Por favor selecciona órdenes y una acción');
      return;
    }

    switch (_accionSeleccionada) {
      case 'Eliminar':
        _eliminarOrdenesSeleccionadas();
        break;
      case 'Cambiar fecha de entrega':
        if (_nuevaFechaEntrega == null) {
          _mostrarMensaje('Por favor selecciona una fecha de entrega');
          return;
        }
        _cambiarFechaEntrega();
        break;
      case 'Cambiar estado de orden':
        if (_nuevoEstado == null) {
          _mostrarMensaje('Por favor selecciona un estado');
          return;
        }
        _cambiarEstadoOrdenes();
        break;
      case 'Cambiar repartidor asignado':
        if (_nuevoRepartidor == null) {
          _mostrarMensaje('Por favor selecciona un repartidor');
          return;
        }
        _cambiarRepartidor();
        break;
    }
  }

  Future<void> _eliminarOrdenesSeleccionadas() async {
    try {
      // Eliminar de Supabase
      for (String ordenId in _ordenesSeleccionadas) {
        await supabase
            .from('ordenes')
            .delete()
            .eq('id', ordenId);
      }

      // Recargar órdenes
      await _cargarOrdenes();

      setState(() {
        _ordenesSeleccionadas.clear();
        _seleccionarTodo = false;
        _accionSeleccionada = null;
      });

      _mostrarMensaje('Órdenes eliminadas exitosamente');
    } catch (e) {
      // print('Error al eliminar órdenes: $e');
      _mostrarMensaje('Error al eliminar órdenes');
    }
  }

  Future<void> _cambiarFechaEntrega() async {
    try {
      int ordenesActualizadas = 0;

      // Actualizar en Supabase
      for (String ordenId in _ordenesSeleccionadas) {
        // Preparar datos de actualización
        Map<String, dynamic> updateData = {
          'fecha_entrega': _nuevaFechaEntrega!.toIso8601String()
        };

        // Si la nueva fecha es futura y la orden estaba atrasada, cambiar estado a POR ENVIAR
        if (_nuevaFechaEntrega!.isAfter(DateTime.now())) {
          // Buscar la orden actual para verificar su estado
          final ordenActual = _ordenes.firstWhere((o) => o.id == ordenId);
          if (ordenActual.estado == 'ATRASADO') {
            updateData['estado'] = 'POR ENVIAR';
            print('Orden $ordenId: cambiando de ATRASADO a POR ENVIAR (fecha futura)');
          }
        }

        await supabase
            .from('ordenes')
            .update(updateData)
            .eq('id', ordenId);
        ordenesActualizadas++;
        print('Actualizada orden $ordenId: fecha entrega = ${_nuevaFechaEntrega}');
      }

      // Recargar órdenes
      await _cargarOrdenes();

      setState(() {
        _ordenesSeleccionadas.clear();
        _seleccionarTodo = false;
        _accionSeleccionada = null;
        _nuevaFechaEntrega = null;
      });

      // print('Total de órdenes actualizadas: $ordenesActualizadas');
      _mostrarMensaje('Fecha de entrega actualizada en $ordenesActualizadas órdenes');
    } catch (e) {
      // print('Error al actualizar fecha: $e');
      _mostrarMensaje('Error al actualizar fecha de entrega');
    }
  }

  Future<void> _cambiarEstadoOrdenes() async {
    // Advertencia especial si se marca como ENTREGADO desde el panel web
    if (_nuevoEstado == 'ENTREGADO') {
      final confirmado = await _mostrarConfirmacionEntregado();
      if (!confirmado) {
        return;
      }
    }

    try {
      int ordenesActualizadas = 0;

      // Actualizar en Supabase
      for (String ordenId in _ordenesSeleccionadas) {
        await supabase
            .from('ordenes')
            .update({'estado': _nuevoEstado!})
            .eq('id', ordenId);
        ordenesActualizadas++;
        print('Actualizada orden $ordenId: nuevo estado = ${_nuevoEstado}');
      }

      // Recargar órdenes
      await _cargarOrdenes();

      setState(() {
        _ordenesSeleccionadas.clear();
        _seleccionarTodo = false;
        _accionSeleccionada = null;
        _nuevoEstado = null;
      });

      // print('Total de órdenes actualizadas: $ordenesActualizadas');
      _mostrarMensaje('Estado actualizado en $ordenesActualizadas órdenes');
    } catch (e) {
      // print('Error al actualizar estado: $e');
      _mostrarMensaje('Error al actualizar estado');
    }
  }

  Future<void> _cambiarRepartidor() async {
    try {
      int ordenesActualizadas = 0;

      // Actualizar en Supabase
      for (String ordenId in _ordenesSeleccionadas) {
        await supabase
            .from('ordenes')
            .update({'repartidor_nombre': _nuevoRepartidor!})
            .eq('id', ordenId);
        ordenesActualizadas++;
        print('Actualizada orden $ordenId: nuevo repartidor = ${_nuevoRepartidor}');
      }

      // Recargar órdenes
      await _cargarOrdenes();

      setState(() {
        _ordenesSeleccionadas.clear();
        _seleccionarTodo = false;
        _accionSeleccionada = null;
        _nuevoRepartidor = null;
      });

      // print('Total de órdenes actualizadas: $ordenesActualizadas');
      _mostrarMensaje('Repartidor asignado en $ordenesActualizadas órdenes');
    } catch (e) {
      // print('Error al actualizar repartidor: $e');
      _mostrarMensaje('Error al asignar repartidor');
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

  void _mostrarConfirmacionEliminar(Orden orden) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirmar Eliminación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás seguro de que deseas eliminar esta orden?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orden #${orden.numeroOrden}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'De: ${orden.emisor}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Text(
                      'Para: ${orden.receptor}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Text(
                      'Estado: ${orden.estado}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarOrden(orden);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarOrden(Orden orden) async {
    try {
      setState(() => _isLoading = true);

      // Eliminar de Supabase
      await supabase
          .from('ordenes')
          .delete()
          .eq('id', orden.id);

      // Recargar la lista
      await _cargarOrdenes();

      if (mounted) {
        _mostrarMensaje('Orden #${orden.numeroOrden} eliminada exitosamente');
      }
    } catch (e) {
      // print('Error al eliminar orden: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar orden: $e'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método para debug - verificar estado actual de las órdenes
  void _debugOrdenes() {
    print('=== DEBUG: Estado actual de las órdenes ===');
    for (var orden in _ordenes) {
      // print('Orden ${orden.id}: Estado=${orden.estado}, FechaEntrega=${orden.fechaEntrega}');
    }
    print('==========================================');
    
    // Mostrar también en un dialog para verificar visualmente
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Estado Actual de las Órdenes'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _ordenes.length,
              itemBuilder: (context, index) {
                final orden = _ordenes[index];
                return ListTile(
                  title: Text('Orden ${orden.id}'),
                  subtitle: Text('Estado: ${orden.estado}\nFecha Entrega: ${orden.fechaEntrega?.toString().split(' ')[0] ?? 'No asignada'}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Métodos para mostrar submenús
  void _mostrarSelectorFecha() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((fecha) {
      if (fecha != null) {
        setState(() {
          _nuevaFechaEntrega = fecha;
        });
      }
    });
  }

  void _mostrarSelectorEstado() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Estado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOpcionEstado('POR ENVIAR'),
              _buildOpcionEstado('EN TRANSITO'),
              _buildOpcionEstado('ENTREGADO'),
              _buildOpcionEstado('CANCELADA'),
              _buildOpcionEstado('ATRASADO'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpcionEstado(String estado) {
    return ListTile(
      title: Text(estado),
      onTap: () {
        setState(() {
          _nuevoEstado = estado;
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _mostrarSelectorRepartidor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Repartidor'),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
          content: _repartidores.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No hay repartidores disponibles'),
                )
              : SizedBox(
                  width: 300, // Ancho fijo más pequeño
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _repartidores.length,
                    itemBuilder: (context, index) {
                      final repartidor = _repartidores[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          dense: true, // Hace el ListTile más compacto
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          title: Text(
                            repartidor['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            repartidor['email'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () {
                            setState(() {
                              _nuevoRepartidor = repartidor['nombre'];
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  String _getTextoAccionSeleccionada() {
    switch (_accionSeleccionada) {
      case 'Cambiar fecha de entrega':
        return _nuevaFechaEntrega != null 
            ? 'Fecha: ${_formatDate(_nuevaFechaEntrega!)}'
            : 'Selecciona fecha';
      case 'Cambiar estado de orden':
        return _nuevoEstado != null 
            ? 'Estado: $_nuevoEstado'
            : 'Selecciona estado';
      case 'Cambiar repartidor asignado':
        return _nuevoRepartidor != null 
            ? 'Repartidor: $_nuevoRepartidor'
            : 'Selecciona repartidor';
      case 'Eliminar':
        return 'Eliminar órdenes';
      default:
        return _accionSeleccionada ?? '';
    }
  }

  // Método para construir los chips de filtro
  Widget _buildFiltroChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = label;
          // Limpiar selección cuando cambie el filtro
          _ordenesSeleccionadas.clear();
          _seleccionarTodo = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con título y búsqueda
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Órdenes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const Spacer(),
              // Barra de búsqueda
              Container(
                width: 300,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF666666),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),
              // Botón crear orden
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CrearOrdenScreen(),
                    ),
                  ).then((_) {
                    // Recargar órdenes cuando regrese de crear una nueva
                    _cargarOrdenes();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Crear Orden',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Barra de acciones
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Checkbox para selección múltiple
              Row(
                children: [
                  Checkbox(
                    value: _seleccionarTodo,
                    onChanged: (value) => _toggleSeleccionarTodo(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Seleccionar todo',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Dropdown de acciones
              PopupMenuButton<String>(
                enabled: _ordenesSeleccionadas.isNotEmpty,
                onSelected: _seleccionarAccion,
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'Eliminar',
                    child: Text('Eliminar'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Cambiar fecha de entrega',
                    child: Text('Cambiar fecha de entrega'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Cambiar estado de orden',
                    child: Text('Cambiar estado de orden'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Cambiar repartidor asignado',
                    child: Text('Cambiar repartidor asignado'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ordenesSeleccionadas.isNotEmpty ? Colors.white : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _accionSeleccionada ?? 'Seleccionar acción',
                        style: TextStyle(
                          fontSize: 13,
                          color: _ordenesSeleccionadas.isNotEmpty ? const Color(0xFF666666) : const Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: _ordenesSeleccionadas.isNotEmpty ? const Color(0xFF666666) : const Color(0xFF999999),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Indicador de acción seleccionada
              if (_accionSeleccionada != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2196F3)),
                  ),
                  child: Text(
                    _getTextoAccionSeleccionada(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              
              // Botones de acción
              IconButton(
                onPressed: _ordenesSeleccionadas.isNotEmpty && _accionSeleccionada != null 
                    ? _ejecutarAccion 
                    : null,
                icon: const Icon(Icons.play_arrow, size: 20),
                color: _ordenesSeleccionadas.isNotEmpty && _accionSeleccionada != null 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFF999999),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 20),
                color: const Color(0xFF666666),
              ),
              // Botón de debug temporal
              IconButton(
                onPressed: _debugOrdenes,
                icon: const Icon(Icons.bug_report, size: 20),
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
        ),
        
        // Selector de filtros de estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Filtrar por estado:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(width: 16),
              _buildFiltroChip('TODAS', _filtroEstado == 'TODAS'),
              const SizedBox(width: 8),
              _buildFiltroChip('ACTIVAS', _filtroEstado == 'ACTIVAS'),
              const SizedBox(width: 8),
              _buildFiltroChip('ATRASADAS', _filtroEstado == 'ATRASADAS'),
              const SizedBox(width: 8),
              _buildFiltroChip('ENTREGADAS', _filtroEstado == 'ENTREGADAS'),
              const SizedBox(width: 8),
              _buildFiltroChip('CANCELADAS', _filtroEstado == 'CANCELADAS'),
              const SizedBox(width: 8),
              _buildFiltroChip('URGENTES', _filtroEstado == 'URGENTES'),
              const Spacer(),
              Text(
                _ordenesSeleccionadas.isNotEmpty
                    ? '${_ordenesSeleccionadas.length} de ${_ordenesFiltradas.length} órdenes seleccionadas'
                    : '${_ordenesFiltradas.length} órdenes encontradas',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
        
        // Tabla de órdenes
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(const Color(0xFFFAFAFA)),
                headingTextStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2C2C2C),
                ),
                columns: const [
                  DataColumn(label: SizedBox(width: 50, child: Text(''))),
                  DataColumn(label: SizedBox(width: 100, child: Text('NÚMERO'))),
                  DataColumn(label: SizedBox(width: 120, child: Text('Acciones'))),
                  DataColumn(label: SizedBox(width: 140, child: Text('ESTADO'))),
                  DataColumn(label: SizedBox(width: 80, child: Text('BULTOS'))),
                  DataColumn(label: SizedBox(width: 120, child: Text('Repartidor Asignado'))),
                  DataColumn(label: SizedBox(width: 140, child: Text('EMISOR'))),
                  DataColumn(label: SizedBox(width: 140, child: Text('DESTINATARIO'))),
                  DataColumn(label: SizedBox(width: 120, child: Text('DIRECCIÓN'))),
                  DataColumn(label: SizedBox(width: 100, child: Text('FECHA ENVIO'))),
                  DataColumn(label: SizedBox(width: 100, child: Text('FECHA ENTREGA'))),
                  DataColumn(label: SizedBox(width: 150, child: Text('OBSERVACIONES'))),
                  DataColumn(label: SizedBox(width: 100, child: Text('CREADA POR'))),
                ],
                rows: _ordenesFiltradas.map((orden) => _buildDataRow(orden)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(Orden orden) {
    return DataRow(
      // Fondo rojo para órdenes urgentes
      color: orden.esUrgente 
          ? MaterialStateProperty.all(const Color(0xFFFFEBEE)) // Rojo muy claro
          : null,
      cells: [
        DataCell(
          SizedBox(
            width: 50,
            child: GestureDetector(
              onTap: () {}, // Detener propagación del evento
              child: Checkbox(
                value: _isOrdenSeleccionada(orden.id),
                onChanged: (value) => _toggleSeleccionOrden(orden.id),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: orden.esUrgente 
                    ? const Color(0xFFDC2626).withOpacity(0.1) // Rojo para urgentes
                    : const Color(0xFF1976D2).withOpacity(0.1), // Azul normal
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: orden.esUrgente 
                      ? const Color(0xFFDC2626) // Rojo para urgentes
                      : const Color(0xFF1976D2), // Azul normal
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (orden.esUrgente) ...[
                    const Icon(
                      Icons.warning,
                      size: 12,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '#${orden.numeroOrden}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: orden.esUrgente 
                          ? const Color(0xFFDC2626) // Rojo para urgentes
                          : const Color(0xFF1976D2), // Azul normal
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 120, 
            child: GestureDetector(
              onTap: () {}, // Detener propagación del evento
              child: _buildActionButtons(orden),
            ),
          ),
        ),
        DataCell(SizedBox(width: 140, child: _buildStatusTag(_getEstadoReal(orden), _getStatusColor(_getEstadoReal(orden))))),
        DataCell(
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inventory_2,
                    size: 14,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    orden.cantidadBultos.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(SizedBox(width: 120, child: _buildRepartidorTag(orden.repartidor))),
        DataCell(SizedBox(width: 140, child: Text(orden.emisor, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 140, child: Text(orden.receptor, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 120, child: Text(orden.direccionDestino, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: Text(_formatDate(orden.fechaCreacion), overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: Text(orden.fechaEntrega != null ? _formatDate(orden.fechaEntrega!) : '-', overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 150, child: Text(orden.descripcion, overflow: TextOverflow.ellipsis))),
        DataCell(SizedBox(width: 100, child: const Text('Super-Admin', overflow: TextOverflow.ellipsis))),
      ],
    );
  }

  Widget _buildRepartidorTag(String? repartidor) {
    if (repartidor == null || repartidor.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off,
              size: 12,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Sin asignar',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Azul muy claro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 12,
            color: const Color(0xFF1976D2),
          ),
          const SizedBox(width: 4),
          Text(
            repartidor,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    IconData icon;
    switch (text) {
      case 'ENTREGADO':
        icon = Icons.check_circle;
        break;
      case 'EN TRANSITO':
        icon = Icons.local_shipping;
        break;
      case 'POR ENVIAR':
        icon = Icons.schedule;
        break;
      case 'CANCELADA':
        icon = Icons.cancel;
        break;
      case 'ATRASADO':
        icon = Icons.warning;
        break;
      default:
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Orden orden) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            // Ver detalles de la orden
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SharedLayout(
                  currentScreen: 'ordenes',
                  child: VerOrdenScreen(orden: orden),
                ),
              ),
            );
          },
          icon: const Icon(Icons.visibility, size: 14),
          color: const Color(0xFF1976D2),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          tooltip: 'Ver detalles',
        ),
        IconButton(
          onPressed: () {
            // Editar orden
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SharedLayout(
                  currentScreen: 'ordenes',
                  child: EditarOrdenScreen(orden: orden),
                ),
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 14),
          color: const Color(0xFFFF9800),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          tooltip: 'Editar orden',
        ),
        IconButton(
          onPressed: () {
            // Eliminar orden
            _mostrarConfirmacionEliminar(orden);
          },
          icon: const Icon(Icons.delete, size: 14),
          color: const Color(0xFFDC2626),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          tooltip: 'Eliminar orden',
        ),
      ],
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'ENTREGADO':
        return const Color(0xFF4CAF50); // Verde vibrante
      case 'EN TRANSITO':
        return const Color(0xFF2196F3); // Azul fuerte
      case 'POR ENVIAR':
        return const Color(0xFFFF9800); // Naranja energético
      case 'CANCELADA':
        return const Color(0xFF9E9E9E); // Gris
      case 'ATRASADO':
        return const Color(0xFFDC2626); // Rojo intenso - URGENTE
      default:
        return const Color(0xFF9E9E9E); // Gris
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _mostrarConfirmacionEntregado() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFFF9800), size: 24),
            SizedBox(width: 12),
            Text(
              'Advertencia',
              style: TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '⚠️ Estás marcando órdenes como ENTREGADAS desde el panel de administración.\n\nEsto omite las validaciones de:\n• Foto de entrega obligatoria\n• Cobro de dinero al cliente\n\n¿Estás seguro de que quieres continuar?',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
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
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }
}
