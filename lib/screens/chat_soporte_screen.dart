import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../config/app_colors.dart';

class ChatSoporteScreen extends StatefulWidget {
  const ChatSoporteScreen({super.key});

  @override
  State<ChatSoporteScreen> createState() => _ChatSoporteScreenState();
}

class _ChatSoporteScreenState extends State<ChatSoporteScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _conversacionId;
  List<Map<String, dynamic>> _mensajes = [];
  bool _cargando = true;
  String _nombreRepartidor = '';
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _inicializarChat() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      print('🔍 Inicializando chat para usuario: ${user.id}');
      
      // Obtener nombre del repartidor
      final userData = await supabase
          .from('usuarios')
          .select('nombre')
          .eq('auth_id', user.id)  // Usar auth_id en lugar de id
          .single();
      
      if (mounted) {
        setState(() {
          _nombreRepartidor = userData['nombre'] ?? 'Repartidor';
        });
      }
      
      print('👤 Nombre del repartidor: $_nombreRepartidor');

      // Buscar conversación existente o crear una nueva
      print('🔍 Buscando conversación existente...');
      final conversaciones = await supabase
          .from('conversaciones_soporte')
          .select('id')
          .eq('repartidor_auth_id', user.id)
          .eq('estado', 'ABIERTA')
          .limit(1);

      print('📊 Conversaciones encontradas: ${conversaciones.length}');

      if (conversaciones.isEmpty) {
        // Crear nueva conversación
        print('🆕 Creando nueva conversación...');
        final nuevaConversacion = await supabase
            .from('conversaciones_soporte')
            .insert({
          'repartidor_auth_id': user.id,
          'estado': 'ABIERTA',
        }).select('id').single();

        _conversacionId = nuevaConversacion['id'];
        print('✅ Nueva conversación creada: $_conversacionId');
      } else {
        _conversacionId = conversaciones[0]['id'];
        print('✅ Conversación existente encontrada: $_conversacionId');
      }

      // Cargar mensajes existentes
      await _cargarMensajes();

      // Suscribirse a nuevos mensajes en tiempo real
      _suscribirseAMensajes();

      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }

      // Scroll al final
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ Error al inicializar chat: $e');
      
      // Esto es normal si es la primera vez que se usa el chat
      // No mostrar error al usuario, simplemente preparar para crear conversación
      if (mounted) {
        setState(() {
          _cargando = false;
          // Mantener el nombre del repartidor si ya se obtuvo
          if (_nombreRepartidor.isEmpty) {
            _nombreRepartidor = 'Repartidor';
          }
        });
      }
    }
  }

  Future<void> _cargarMensajes() async {
    if (_conversacionId == null) {
      print('⚠️ No hay conversación para cargar mensajes');
      return;
    }

    try {
      print('📥 Cargando mensajes para conversación: $_conversacionId');
      final mensajes = await supabase
          .from('mensajes_soporte')
          .select('*')
          .eq('conversacion_id', _conversacionId!)
          .order('created_at', ascending: true);

      print('📨 Mensajes cargados: ${mensajes.length}');
      
      if (mounted) {
        setState(() {
          _mensajes = List<Map<String, dynamic>>.from(mensajes);
        });
      }

      // Marcar mensajes como leídos
      await _marcarComoLeidos();
    } catch (e) {
      print('❌ Error al cargar mensajes: $e');
    }
  }

  void _suscribirseAMensajes() {
    if (_conversacionId == null) {
      print('⚠️ No hay conversación para suscribirse');
      return;
    }

    print('🔔 Suscribiéndose a mensajes de conversación: $_conversacionId');
    
    _channel = supabase
        .channel('mensajes_soporte_$_conversacionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_soporte',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversacion_id',
            value: _conversacionId,
          ),
          callback: (payload) async {
            print('🔔 Nuevo mensaje recibido por realtime!');
            print('📦 Payload completo: $payload');
            
            try {
              // Usar directamente los datos del payload
              final nuevoMensaje = payload.newRecord;
              print('📨 Mensaje del payload: ${nuevoMensaje['mensaje']}');

              if (mounted) {
                setState(() {
                  _mensajes.add(nuevoMensaje);
                });
                print('✅ Mensaje agregado a la UI, total: ${_mensajes.length}');
                
                // Scroll automático después de un pequeño delay
                Future.delayed(const Duration(milliseconds: 100), () {
                  _scrollToBottom();
                });
                
                // Marcar como leído si no es del usuario actual
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
            value: _conversacionId,
          ),
          callback: (payload) async {
            print('🔄 Mensaje actualizado por realtime!');
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
        .subscribe((status, error) {
      print('📡 Estado de suscripción: $status');
      if (error != null) {
        print('❌ Error en suscripción: $error');
      }
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('✅ Suscripción CONFIRMADA y ACTIVA para conversación: $_conversacionId');
      }
    });
    
    print('✅ Suscripción a realtime iniciada');
  }

  Future<void> _marcarComoLeidos() async {
    final user = supabase.auth.currentUser;
    if (user == null || _conversacionId == null) return;

    try {
      await supabase
          .from('mensajes_soporte')
          .update({'leido': true})
          .eq('conversacion_id', _conversacionId!)
          .neq('remitente_auth_id', user.id)
          .eq('leido', false);
    } catch (e) {
      print('Error al marcar mensajes como leídos: $e');
    }
  }

  Future<void> _enviarMensaje() async {
    print('🔵 _enviarMensaje llamado');
    
    final user = supabase.auth.currentUser;
    if (user == null || _mensajeController.text.trim().isEmpty) {
      print('⚠️ Usuario null o mensaje vacío');
      return;
    }

    final mensaje = _mensajeController.text.trim();
    print('📝 Mensaje a enviar: $mensaje');
    print('🔑 ConversacionId: $_conversacionId');
    
    // Si no hay conversación, buscar o crear una
    if (_conversacionId == null) {
      print('❌ No hay conversación, buscando o creando...');
      _mensajeController.clear();
      
      try {
        // Primero buscar si ya existe una conversación
        final conversacionesExistentes = await supabase
            .from('conversaciones_soporte')
            .select('id')
            .eq('repartidor_auth_id', user.id)
            .eq('estado', 'ABIERTA')
            .limit(1);

        if (conversacionesExistentes.isNotEmpty) {
          // Usar conversación existente
          _conversacionId = conversacionesExistentes[0]['id'];
          print('✅ Conversación existente encontrada: $_conversacionId');
        } else {
          // Crear nueva conversación solo si no existe
          final nuevaConversacion = await supabase
              .from('conversaciones_soporte')
              .insert({
            'repartidor_auth_id': user.id,
            'estado': 'ABIERTA',
          }).select('id').single();

          _conversacionId = nuevaConversacion['id'];
          print('✅ Nueva conversación creada: $_conversacionId');
        }
        
        // Reintentar enviar el mensaje
        await supabase.from('mensajes_soporte').insert({
          'conversacion_id': _conversacionId,
          'remitente_auth_id': user.id,
          'mensaje': mensaje,
          'leido': false,
        });
        
        print('✅ Mensaje enviado exitosamente');
        
        // Cargar mensajes después de crear la conversación
        await _cargarMensajes();
        _scrollToBottom();
        
        // Suscribirse a mensajes ahora que tenemos conversación
        _suscribirseAMensajes();
        
      } catch (e) {
        print('❌ Error al crear conversación o enviar: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    _mensajeController.clear();

    try {
      print('📤 Enviando mensaje...');
      await supabase.from('mensajes_soporte').insert({
        'conversacion_id': _conversacionId,
        'remitente_auth_id': user.id,
        'mensaje': mensaje,
        'leido': false,
      });

      print('✅ Mensaje enviado exitosamente');
      
      // Recargar mensajes para asegurar que se muestren
      await _cargarMensajes();
      _scrollToBottom();
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
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
    return Scaffold(
      backgroundColor: AppColors.fondoGeneral,
      appBar: AppBar(
        backgroundColor: AppColors.header,
        title: const Text(
          'Chat de Soporte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Área de mensajes
                Expanded(
                  child: _mensajes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: AppColors.textoSecundario.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '¡Hola $_nombreRepartidor!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textoPrincipal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Escribe un mensaje para contactar con soporte',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textoSecundario,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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
                            final nombreRemitente = esMio ? _nombreRepartidor : 'Administrador';
                            final rolRemitente = esMio ? 'REPARTIDOR' : 'ADMINISTRADOR';
                            final esAdmin = rolRemitente == 'ADMINISTRADOR';

                            return _buildMensajeBurbuja(
                              mensaje['mensaje'],
                              esMio,
                              nombreRemitente,
                              esAdmin,
                              DateTime.parse(mensaje['created_at']),
                            );
                          },
                        ),
                ),

                // Campo de entrada de mensaje
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esMio) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: esAdmin ? AppColors.success : AppColors.primary,
              child: Icon(
                esAdmin ? Icons.admin_panel_settings : Icons.person,
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
                      esAdmin ? 'Administrador' : nombreRemitente,
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: const Icon(
                Icons.delivery_dining,
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
      // Hoy - mostrar solo hora
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      return '$hora:$minuto';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays} días';
    } else {
      // Fecha completa
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}



