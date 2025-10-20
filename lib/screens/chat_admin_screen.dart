import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../config/app_colors.dart';
import '../widgets/shared_layout.dart';

class ChatAdminScreen extends StatefulWidget {
  const ChatAdminScreen({super.key});

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  List<Map<String, dynamic>> _conversaciones = [];
  bool _cargando = true;
  RealtimeChannel? _channelConversaciones;

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
    _suscribirseAConversaciones();
  }

  @override
  void dispose() {
    _channelConversaciones?.unsubscribe();
    super.dispose();
  }

  Future<void> _cargarConversaciones() async {
    try {
      print('🔍 Cargando conversaciones...');
      
      // Primero obtener todas las conversaciones
      final conversaciones = await supabase
          .from('conversaciones_soporte')
          .select('*')
          .order('ultimo_mensaje_fecha', ascending: false);

      print('📊 Conversaciones encontradas: ${conversaciones.length}');

      // Para cada conversación, obtener el repartidor y mensajes
      for (var conv in conversaciones) {
        // Obtener datos del repartidor usando auth_id
        final repartidorData = await supabase
            .from('usuarios')
            .select('id, nombre, email, foto_perfil')
            .eq('auth_id', conv['repartidor_auth_id'])
            .single();
        
        conv['usuarios'] = repartidorData;

        // Obtener mensajes de esta conversación
        final mensajes = await supabase
            .from('mensajes_soporte')
            .select('id, mensaje, created_at, leido, remitente_auth_id')
            .eq('conversacion_id', conv['id'])
            .order('created_at', ascending: true);

        final adminId = supabase.auth.currentUser?.id;
        
        conv['mensajes_no_leidos'] = mensajes
            .where((m) => !m['leido'] && m['remitente_auth_id'] != adminId)
            .length;
        
        conv['ultimo_mensaje'] = mensajes.isNotEmpty
            ? mensajes.last['mensaje']
            : 'Sin mensajes';
      }

      print('✅ Conversaciones cargadas con éxito');

      if (mounted) {
        setState(() {
          _conversaciones = List<Map<String, dynamic>>.from(conversaciones);
          _cargando = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar conversaciones: $e');
      
      // FIX TEMPORAL: Si las tablas no existen, mostrar estado vacío
      if (mounted) {
        setState(() {
          _conversaciones = [];
          _cargando = false;
        });
        
        // Mostrar mensaje de error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Chat temporalmente no disponible. Ejecuta el SQL en Supabase.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _suscribirseAConversaciones() {
    _channelConversaciones = supabase
        .channel('conversaciones_soporte_admin')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversaciones_soporte',
          callback: (payload) {
            _cargarConversaciones();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mensajes_soporte',
          callback: (payload) {
            _cargarConversaciones();
          },
        )
        .subscribe();
  }

  Future<void> _cerrarConversacion(String conversacionId) async {
    try {
      await supabase
          .from('conversaciones_soporte')
          .update({'estado': 'CERRADA'})
          .eq('id', conversacionId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversación cerrada'),
          backgroundColor: AppColors.success,
        ),
      );

      await _cargarConversaciones();
    } catch (e) {
      print('Error al cerrar conversación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar conversación'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _abrirConversacion(String conversacionId) async {
    try {
      await supabase
          .from('conversaciones_soporte')
          .update({'estado': 'ABIERTA'})
          .eq('id', conversacionId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversación reabierta'),
          backgroundColor: AppColors.success,
        ),
      );

      await _cargarConversaciones();
    } catch (e) {
      print('Error al abrir conversación: $e');
    }
  }

  Future<void> _mostrarConfirmacionEliminar(Map<String, dynamic> conversacion) async {
    final repartidor = conversacion['usuarios'];
    final nombreRepartidor = repartidor['nombre'] ?? 'Repartidor';
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Eliminar Conversación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrincipal,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar permanentemente la conversación con $nombreRepartidor?',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer. Se eliminarán todos los mensajes de esta conversación.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textoSecundario,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _eliminarConversacion(conversacion['id']);
    }
  }

  Future<void> _eliminarConversacion(String conversacionId) async {
    try {
      print('🗑️ Eliminando conversación: $conversacionId');
      
      // Eliminar todos los mensajes de la conversación primero
      await supabase
          .from('mensajes_soporte')
          .delete()
          .eq('conversacion_id', conversacionId);

      print('✅ Mensajes eliminados');

      // Eliminar la conversación
      await supabase
          .from('conversaciones_soporte')
          .delete()
          .eq('id', conversacionId);

      print('✅ Conversación eliminada');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Conversación eliminada permanentemente'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        // Recargar la lista de conversaciones
        await _cargarConversaciones();
      }
    } catch (e) {
      print('❌ Error al eliminar conversación: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar conversación: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _mostrarModalNuevaConversacion() async {
    try {
      // Obtener todos los repartidores
      final repartidores = await supabase
          .from('usuarios')
          .select('id, auth_id, nombre, email, foto_perfil')
          .eq('rol', 'REPARTIDOR')
          .order('nombre', ascending: true);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Nueva Conversación',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona un repartidor para iniciar una conversación',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textoSecundario,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: repartidores.length,
                    itemBuilder: (context, index) {
                      final repartidor = repartidores[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          backgroundImage: repartidor['foto_perfil'] != null &&
                                  repartidor['foto_perfil'].isNotEmpty
                              ? NetworkImage(repartidor['foto_perfil'])
                              : null,
                          child: repartidor['foto_perfil'] == null ||
                                  repartidor['foto_perfil'].isEmpty
                              ? Text(
                                  repartidor['nombre'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          repartidor['nombre'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        subtitle: Text(
                          repartidor['email'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          Navigator.pop(context);
                          await _crearOAbrirConversacion(repartidor);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error al mostrar modal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar repartidores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _crearOAbrirConversacion(Map<String, dynamic> repartidor) async {
    try {
      print('🔍 Buscando conversación con repartidor: ${repartidor['nombre']}');
      
      // Buscar si ya existe una conversación con este repartidor
      final conversacionesExistentes = await supabase
          .from('conversaciones_soporte')
          .select('id')
          .eq('repartidor_auth_id', repartidor['auth_id'])
          .eq('estado', 'ABIERTA')
          .limit(1);

      String conversacionId;

      if (conversacionesExistentes.isEmpty) {
        // Crear nueva conversación
        print('🆕 Creando nueva conversación...');
        final nuevaConversacion = await supabase
            .from('conversaciones_soporte')
            .insert({
          'repartidor_auth_id': repartidor['auth_id'],
          'estado': 'ABIERTA',
        }).select('id').single();

        conversacionId = nuevaConversacion['id'];
        print('✅ Nueva conversación creada: $conversacionId');
      } else {
        conversacionId = conversacionesExistentes[0]['id'];
        print('✅ Conversación existente encontrada: $conversacionId');
      }

      // Abrir la conversación
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatAdminConversacionScreen(
              conversacionId: conversacionId,
              nombreRepartidor: repartidor['nombre'],
              fotoPerfilUrl: repartidor['foto_perfil'],
            ),
          ),
        );

        // Recargar conversaciones al volver
        _cargarConversaciones();
      }
    } catch (e) {
      print('❌ Error al crear/abrir conversación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentScreen: 'chat_soporte',
      child: Stack(
        children: [
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : _conversaciones.isEmpty
                  ? _buildEmptyState()
                  : _buildConversacionesList(),
          // Botón flotante "+" para iniciar nueva conversación
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: _mostrarModalNuevaConversacion,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textoSecundario.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay conversaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando los repartidores inicien conversaciones aparecerán aquí',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textoSecundario,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversacionesList() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chat de Soporte',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                  letterSpacing: 0.3,
                  height: 1.4,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_conversaciones.where((c) => c['estado'] == 'ABIERTA').length} activas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _cargarConversaciones,
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de conversaciones
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bordeClaro),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _conversaciones.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversacion = _conversaciones[index];
                  return _buildConversacionItem(conversacion);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversacionItem(Map<String, dynamic> conversacion) {
    final repartidor = conversacion['usuarios'];
    final nombreRepartidor = repartidor?['nombre'] ?? 'Repartidor';
    final emailRepartidor = repartidor?['email'] ?? '';
    final fotoPerfilUrl = repartidor?['foto_perfil'];
    final estado = conversacion['estado'];
    final mensajesNoLeidos = conversacion['mensajes_no_leidos'] ?? 0;
    final ultimoMensaje = conversacion['ultimo_mensaje'] ?? 'Sin mensajes';
    final ultimaFecha = conversacion['ultimo_mensaje_fecha'];

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatAdminConversacionScreen(
              conversacionId: conversacion['id'],
              nombreRepartidor: nombreRepartidor,
              fotoPerfilUrl: fotoPerfilUrl,
            ),
          ),
        ).then((_) => _cargarConversaciones());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Foto de perfil
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accent,
                  backgroundImage: fotoPerfilUrl != null && fotoPerfilUrl.isNotEmpty
                      ? NetworkImage(fotoPerfilUrl)
                      : null,
                  child: fotoPerfilUrl == null || fotoPerfilUrl.isEmpty
                      ? Text(
                          nombreRepartidor[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (mensajesNoLeidos > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        mensajesNoLeidos > 9 ? '9+' : '$mensajesNoLeidos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Información de la conversación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        nombreRepartidor,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: mensajesNoLeidos > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: estado == 'ABIERTA'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.textoSecundario.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          estado == 'ABIERTA' ? 'ABIERTA' : 'CERRADA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: estado == 'ABIERTA'
                                ? AppColors.success
                                : AppColors.textoSecundario,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emailRepartidor,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ultimoMensaje.length > 60
                        ? '${ultimoMensaje.substring(0, 60)}...'
                        : ultimoMensaje,
                    style: TextStyle(
                      fontSize: 13,
                      color: mensajesNoLeidos > 0
                          ? AppColors.textoPrincipal
                          : AppColors.textoSecundario,
                      fontWeight: mensajesNoLeidos > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Fecha y acciones
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ultimaFecha != null)
                  Text(
                    _formatearFecha(DateTime.parse(ultimaFecha)),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'cerrar') {
                      _cerrarConversacion(conversacion['id']);
                    } else if (value == 'abrir') {
                      _abrirConversacion(conversacion['id']);
                    } else if (value == 'eliminar') {
                      _mostrarConfirmacionEliminar(conversacion);
                    }
                  },
                  itemBuilder: (context) => [
                    if (estado == 'ABIERTA')
                      const PopupMenuItem(
                        value: 'cerrar',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Cerrar conversación'),
                          ],
                        ),
                      ),
                    if (estado == 'CERRADA')
                      const PopupMenuItem(
                        value: 'abrir',
                        child: Row(
                          children: [
                            Icon(Icons.replay, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Reabrir conversación'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar conversación'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: AppColors.textoSecundario,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      return '$hora:$minuto';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays}d';
    } else {
      return '${fecha.day}/${fecha.month}';
    }
  }
}

// Pantalla de conversación individual para el administrador
class ChatAdminConversacionScreen extends StatefulWidget {
  final String conversacionId;
  final String nombreRepartidor;
  final String? fotoPerfilUrl;

  const ChatAdminConversacionScreen({
    super.key,
    required this.conversacionId,
    required this.nombreRepartidor,
    this.fotoPerfilUrl,
  });

  @override
  State<ChatAdminConversacionScreen> createState() =>
      _ChatAdminConversacionScreenState();
}

class _ChatAdminConversacionScreenState
    extends State<ChatAdminConversacionScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _mensajes = [];
  bool _cargando = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _suscribirseAMensajes();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    try {
      print('📥 Cargando mensajes admin para conversación: ${widget.conversacionId}');
      
      final mensajes = await supabase
          .from('mensajes_soporte')
          .select('*')
          .eq('conversacion_id', widget.conversacionId)
          .order('created_at', ascending: true);

      print('📨 Mensajes cargados (admin): ${mensajes.length}');

      if (mounted) {
        setState(() {
          _mensajes = List<Map<String, dynamic>>.from(mensajes);
          _cargando = false;
        });
      }

      await _marcarComoLeidos();

      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ Error al cargar mensajes: $e');
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _suscribirseAMensajes() {
    print('🔔 Suscribiéndose a mensajes (admin) para conversación: ${widget.conversacionId}');
    
    _channel = supabase
        .channel('mensajes_soporte_admin_${widget.conversacionId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_soporte',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversacion_id',
            value: widget.conversacionId,
          ),
          callback: (payload) async {
            print('🔔 Nuevo mensaje recibido por realtime (admin)!');
            print('📦 Payload completo: $payload');
            
            try {
              // Usar directamente los datos del payload en lugar de hacer otra consulta
              final nuevoMensaje = payload.newRecord;
              print('📨 Mensaje del payload: ${nuevoMensaje['mensaje']}');

              if (mounted) {
                setState(() {
                  _mensajes.add(nuevoMensaje);
                });
                print('✅ Mensaje agregado a la UI (admin), total: ${_mensajes.length}');
                
                // Scroll automático después de un pequeño delay
                Future.delayed(const Duration(milliseconds: 100), () {
                  _scrollToBottom();
                });

                final user = supabase.auth.currentUser;
                if (user != null && nuevoMensaje['remitente_auth_id'] != user.id) {
                  _marcarComoLeidos();
                }
              }
            } catch (e) {
              print('❌ Error procesando mensaje realtime: $e');
              // Si hay error, recargar todos los mensajes
              _cargarMensajes();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'mensajes_soporte',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversacion_id',
            value: widget.conversacionId,
          ),
          callback: (payload) async {
            print('🔄 Mensaje actualizado por realtime (admin)!');
            try {
              final mensajeActualizado = payload.newRecord;
              final mensajeId = mensajeActualizado['id'];
              
              if (mounted) {
                setState(() {
                  final index = _mensajes.indexWhere((m) => m['id'] == mensajeId);
                  if (index != -1) {
                    _mensajes[index] = mensajeActualizado;
                  }
                });
              }
            } catch (e) {
              print('❌ Error actualizando mensaje: $e');
            }
          },
        )
        .subscribe();
    
    print('✅ Suscripción a realtime completada (admin)');
  }

  Future<void> _marcarComoLeidos() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('mensajes_soporte')
          .update({'leido': true})
          .eq('conversacion_id', widget.conversacionId)
          .neq('remitente_auth_id', user.id)
          .eq('leido', false);
    } catch (e) {
      print('Error al marcar mensajes como leídos: $e');
    }
  }

  Future<void> _enviarMensaje() async {
    final user = supabase.auth.currentUser;
    if (user == null || _mensajeController.text.trim().isEmpty) {
      return;
    }

    final mensaje = _mensajeController.text.trim();
    _mensajeController.clear();

    try {
      print('📤 Enviando mensaje (admin)...');
      await supabase.from('mensajes_soporte').insert({
        'conversacion_id': widget.conversacionId,
        'remitente_auth_id': user.id,
        'mensaje': mensaje,
        'leido': false,
      });

      print('✅ Mensaje enviado exitosamente (admin)');
      
      // Recargar mensajes para asegurar que se muestren
      await _cargarMensajes();
      _scrollToBottom();
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentScreen: 'chat_soporte',
      child: Column(
        children: [
          // Header personalizado para el chat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.header,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent,
                  backgroundImage: widget.fotoPerfilUrl != null &&
                          widget.fotoPerfilUrl!.isNotEmpty
                      ? NetworkImage(widget.fotoPerfilUrl!)
                      : null,
                  child: widget.fotoPerfilUrl == null ||
                          widget.fotoPerfilUrl!.isEmpty
                      ? Text(
                          widget.nombreRepartidor[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.nombreRepartidor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Contenido del chat
          Expanded(
            child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _mensajes.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay mensajes',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _mensajes.length,
                          itemBuilder: (context, index) {
                            final mensaje = _mensajes[index];
                            final user = supabase.auth.currentUser;
                            final esMio = mensaje['remitente_auth_id'] == user?.id;
                            final nombreRemitente = esMio ? 'Administrador' : widget.nombreRepartidor;

                            return _buildMensajeBurbuja(
                              mensaje['mensaje'],
                              esMio,
                              nombreRemitente,
                              esMio, // esAdmin = esMio (si es mío, es admin)
                              DateTime.parse(mensaje['created_at']),
                            );
                          },
                        ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mensajeController,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              hintStyle: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppColors.fondoGeneral,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _enviarMensaje(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: _enviarMensaje,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 22,
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
        ],
      ),
    );
  }

  Widget _buildMensajeBurbuja(
    String mensaje,
    bool esMio,
    String nombreRemitente,
    bool esAdmin,
    DateTime fecha,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esMio) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: const Icon(
                Icons.delivery_dining,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!esMio)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      nombreRemitente,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: esMio ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(esMio ? 16 : 4),
                      bottomRight: Radius.circular(esMio ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 14,
                      color: esMio ? Colors.white : AppColors.textoPrincipal,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                  child: Text(
                    _formatearHora(fecha),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (esMio) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.success,
              child: Icon(
                Icons.admin_panel_settings,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatearHora(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      return '$hora:$minuto';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}

