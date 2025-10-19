import 'package:flutter/material.dart';
import '../main.dart';

class EnviosAjustesScreen extends StatefulWidget {
  const EnviosAjustesScreen({super.key});

  @override
  State<EnviosAjustesScreen> createState() => _EnviosAjustesScreenState();
}

class _EnviosAjustesScreenState extends State<EnviosAjustesScreen> {
  bool _isLoading = true;
  String? _configuracionId;
  
  // Configuraciones de prioridad
  bool _prioridadUrgentes = true;
  bool _ordenarPorFecha = false;
  bool _ordenarPorDistancia = true;
  
  // Configuraciones de impresión
  String _tipoImpresion = 'etiqueta_completa'; // 'etiqueta_completa', 'codigo_qr', 'manual'
  bool _incluirQR = true;
  bool _incluirDatosDestinatario = true;
  bool _incluirNumeroOrden = true;
  
  // Configuraciones de rastreo
  bool _mostrarRastreoUsuarios = true;
  bool _rastreoTiempoReal = false;
  int _intervaloActualizacion = 30; // segundos
  
  // Configuraciones de notificaciones
  bool _notificacionesEmisores = true;
  bool _notificacionesDestinatarios = false;
  bool _notificacionesRepartidores = true;
  bool _notificacionesEmail = true;
  bool _notificacionesSMS = false;
  
  // Configuraciones adicionales
  bool _confirmacionEntrega = true;
  bool _fotoEntregaObligatoria = true;
  bool _firmaDigital = false;
  int _tiempoEsperaEntrega = 15; // minutos
  bool _geolocalizacionObligatoria = true;
  double _radioEntrega = 100.0; // metros

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      print('🔄 Cargando configuración de envíos...');
      
      final response = await supabase
          .from('configuracion_envios')
          .select()
          .limit(1)
          .single();

      print('✅ Configuración cargada: $response');

      if (mounted) {
        setState(() {
          _configuracionId = response['id'];
          
          // Prioridad
          _prioridadUrgentes = response['prioridad_urgentes'] ?? true;
          _ordenarPorFecha = response['ordenar_por_fecha'] ?? false;
          _ordenarPorDistancia = response['ordenar_por_distancia'] ?? true;
          
          // Impresión
          _tipoImpresion = response['tipo_impresion'] ?? 'etiqueta_completa';
          _incluirQR = response['incluir_qr'] ?? true;
          _incluirDatosDestinatario = response['incluir_datos_destinatario'] ?? true;
          _incluirNumeroOrden = response['incluir_numero_orden'] ?? true;
          
          // Rastreo
          _mostrarRastreoUsuarios = response['mostrar_rastreo_usuarios'] ?? true;
          _rastreoTiempoReal = response['rastreo_tiempo_real'] ?? false;
          _intervaloActualizacion = response['intervalo_actualizacion'] ?? 30;
          
          // Notificaciones
          _notificacionesEmisores = response['notificaciones_emisores'] ?? true;
          _notificacionesDestinatarios = response['notificaciones_destinatarios'] ?? false;
          _notificacionesRepartidores = response['notificaciones_repartidores'] ?? true;
          _notificacionesEmail = response['notificaciones_email'] ?? true;
          _notificacionesSMS = response['notificaciones_sms'] ?? false;
          
          // Entrega
          _confirmacionEntrega = response['confirmacion_entrega'] ?? true;
          _fotoEntregaObligatoria = response['foto_entrega_obligatoria'] ?? true;
          _firmaDigital = response['firma_digital'] ?? false;
          _tiempoEsperaEntrega = response['tiempo_espera_entrega'] ?? 15;
          
          // Geolocalización
          _geolocalizacionObligatoria = response['geolocalizacion_obligatoria'] ?? true;
          _radioEntrega = (response['radio_entrega'] ?? 100.0).toDouble();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar configuración: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar configuración: $e'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
                const Text(
                  'Ajustes de Envíos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _guardarConfiguracion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSeccionPrioridad(),
                  const SizedBox(height: 24),
                  _buildSeccionImpresion(),
                  const SizedBox(height: 24),
                  _buildSeccionRastreo(),
                  const SizedBox(height: 24),
                  _buildSeccionNotificaciones(),
                  const SizedBox(height: 24),
                  _buildSeccionEntrega(),
                  const SizedBox(height: 24),
                  _buildSeccionGeolocalizacion(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPrioridad() {
    return _buildSeccionCard(
      'Prioridad de Órdenes',
      Icons.priority_high,
      const Color(0xFFDC2626),
      [
        _buildSwitchTile(
          'Priorizar órdenes urgentes',
          'Los repartidores deben entregar primero las órdenes marcadas como urgentes',
          _prioridadUrgentes,
          (value) => setState(() => _prioridadUrgentes = value!),
        ),
        _buildSwitchTile(
          'Ordenar por fecha de creación',
          'Las órdenes más antiguas se entregan primero',
          _ordenarPorFecha,
          (value) => setState(() => _ordenarPorFecha = value!),
        ),
        _buildSwitchTile(
          'Ordenar por distancia',
          'Las órdenes más cercanas se entregan primero',
          _ordenarPorDistancia,
          (value) => setState(() => _ordenarPorDistancia = value!),
        ),
      ],
    );
  }

  Widget _buildSeccionImpresion() {
    return _buildSeccionCard(
      'Configuración de Impresión',
      Icons.print,
      const Color(0xFF2196F3),
      [
        _buildDropdownTile(
          'Tipo de impresión',
          'Selecciona qué imprime la impresora de etiquetas',
          _tipoImpresion,
          {
            'etiqueta_completa': 'Etiqueta Completa',
            'codigo_qr': 'Solo Código QR',
            'manual': 'Modo Manual',
          },
          (value) => setState(() => _tipoImpresion = value!),
        ),
        if (_tipoImpresion == 'etiqueta_completa') ...[
          _buildSwitchTile(
            'Incluir código QR',
            'Genera un código QR para escaneo rápido',
            _incluirQR,
            (value) => setState(() => _incluirQR = value!),
          ),
          _buildSwitchTile(
            'Incluir datos del destinatario',
            'Muestra nombre y dirección del destinatario',
            _incluirDatosDestinatario,
            (value) => setState(() => _incluirDatosDestinatario = value!),
          ),
          _buildSwitchTile(
            'Incluir número de orden',
            'Muestra el número de orden en la etiqueta',
            _incluirNumeroOrden,
            (value) => setState(() => _incluirNumeroOrden = value!),
          ),
        ],
      ],
    );
  }

  Widget _buildSeccionRastreo() {
    return _buildSeccionCard(
      'Rastreo de Órdenes',
      Icons.track_changes,
      const Color(0xFF4CAF50),
      [
        _buildSwitchTile(
          'Mostrar página de rastreo a usuarios',
          'Los usuarios pueden rastrear sus órdenes en tiempo real',
          _mostrarRastreoUsuarios,
          (value) => setState(() => _mostrarRastreoUsuarios = value!),
        ),
        if (_mostrarRastreoUsuarios) ...[
          _buildSwitchTile(
            'Rastreo en tiempo real',
            'Actualización continua de la ubicación del repartidor',
            _rastreoTiempoReal,
            (value) => setState(() => _rastreoTiempoReal = value!),
          ),
          _buildSliderTile(
            'Intervalo de actualización',
            'Frecuencia de actualización del rastreo (segundos)',
            _intervaloActualizacion.toDouble(),
            10.0,
            300.0,
            (value) => setState(() => _intervaloActualizacion = value.round()),
            '${_intervaloActualizacion}s',
          ),
        ],
      ],
    );
  }

  Widget _buildSeccionNotificaciones() {
    return _buildSeccionCard(
      'Notificaciones',
      Icons.notifications,
      const Color(0xFFFF9800),
      [
        _buildSwitchTile(
          'Notificaciones para emisores',
          'Los emisores reciben notificaciones sobre el estado de sus órdenes',
          _notificacionesEmisores,
          (value) => setState(() => _notificacionesEmisores = value!),
        ),
        _buildSwitchTile(
          'Notificaciones para destinatarios',
          'Los destinatarios reciben notificaciones sobre la entrega',
          _notificacionesDestinatarios,
          (value) => setState(() => _notificacionesDestinatarios = value!),
        ),
        _buildSwitchTile(
          'Notificaciones para repartidores',
          'Los repartidores reciben notificaciones de nuevas órdenes',
          _notificacionesRepartidores,
          (value) => setState(() => _notificacionesRepartidores = value!),
        ),
        const Divider(),
        _buildSwitchTile(
          'Notificaciones por email',
          'Enviar notificaciones por correo electrónico',
          _notificacionesEmail,
          (value) => setState(() => _notificacionesEmail = value!),
        ),
        _buildSwitchTile(
          'Notificaciones por SMS',
          'Enviar notificaciones por mensaje de texto',
          _notificacionesSMS,
          (value) => setState(() => _notificacionesSMS = value!),
        ),
      ],
    );
  }

  Widget _buildSeccionEntrega() {
    return _buildSeccionCard(
      'Configuración de Entrega',
      Icons.delivery_dining,
      const Color(0xFF9C27B0),
      [
        _buildSwitchTile(
          'Confirmación de entrega obligatoria',
          'El repartidor debe confirmar la entrega antes de marcar como completada',
          _confirmacionEntrega,
          (value) => setState(() => _confirmacionEntrega = value!),
        ),
        _buildSwitchTile(
          'Foto de entrega obligatoria',
          'El repartidor debe tomar una foto como prueba de entrega',
          _fotoEntregaObligatoria,
          (value) => setState(() => _fotoEntregaObligatoria = value!),
        ),
        _buildSwitchTile(
          'Firma digital',
          'Solicitar firma digital del destinatario',
          _firmaDigital,
          (value) => setState(() => _firmaDigital = value!),
        ),
        _buildSliderTile(
          'Tiempo de espera en entrega',
          'Tiempo máximo de espera en el punto de entrega (minutos)',
          _tiempoEsperaEntrega.toDouble(),
          5.0,
          60.0,
          (value) => setState(() => _tiempoEsperaEntrega = value.round()),
          '${_tiempoEsperaEntrega} min',
        ),
      ],
    );
  }

  Widget _buildSeccionGeolocalizacion() {
    return _buildSeccionCard(
      'Geolocalización',
      Icons.location_on,
      const Color(0xFF607D8B),
      [
        _buildSwitchTile(
          'Geolocalización obligatoria',
          'El repartidor debe activar la ubicación para recibir órdenes',
          _geolocalizacionObligatoria,
          (value) => setState(() => _geolocalizacionObligatoria = value!),
        ),
        _buildSliderTile(
          'Radio de entrega',
          'Distancia máxima desde el punto de entrega para marcar como entregado (metros)',
          _radioEntrega,
          10.0,
          500.0,
          (value) => setState(() => _radioEntrega = value),
          '${_radioEntrega.round()}m',
        ),
      ],
    );
  }

  Widget _buildSeccionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool?> onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C2C2C),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF666666),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1976D2),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, String value, Map<String, String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
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
          items: items.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2C2C2C)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, ValueChanged<double> onChanged, String displayValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF1976D2)),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: const Color(0xFF1976D2),
          inactiveColor: const Color(0xFFE0E0E0),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _guardarConfiguracion() async {
    try {
      print('💾 Guardando configuración...');

      if (_configuracionId == null) {
        throw Exception('No se encontró el ID de configuración');
      }

      final data = {
        // Prioridad
        'prioridad_urgentes': _prioridadUrgentes,
        'ordenar_por_fecha': _ordenarPorFecha,
        'ordenar_por_distancia': _ordenarPorDistancia,
        
        // Impresión
        'tipo_impresion': _tipoImpresion,
        'incluir_qr': _incluirQR,
        'incluir_datos_destinatario': _incluirDatosDestinatario,
        'incluir_numero_orden': _incluirNumeroOrden,
        
        // Rastreo
        'mostrar_rastreo_usuarios': _mostrarRastreoUsuarios,
        'rastreo_tiempo_real': _rastreoTiempoReal,
        'intervalo_actualizacion': _intervaloActualizacion,
        
        // Notificaciones
        'notificaciones_emisores': _notificacionesEmisores,
        'notificaciones_destinatarios': _notificacionesDestinatarios,
        'notificaciones_repartidores': _notificacionesRepartidores,
        'notificaciones_email': _notificacionesEmail,
        'notificaciones_sms': _notificacionesSMS,
        
        // Entrega
        'confirmacion_entrega': _confirmacionEntrega,
        'foto_entrega_obligatoria': _fotoEntregaObligatoria,
        'firma_digital': _firmaDigital,
        'tiempo_espera_entrega': _tiempoEsperaEntrega,
        
        // Geolocalización
        'geolocalizacion_obligatoria': _geolocalizacionObligatoria,
        'radio_entrega': _radioEntrega,
      };

      print('📤 Datos a guardar: $data');

      await supabase
          .from('configuracion_envios')
          .update(data)
          .eq('id', _configuracionId!);

      print('✅ Configuración guardada exitosamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Configuración guardada exitosamente'),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );

        // Aplicar lógica inmediatamente
        await _aplicarLogicaPrioridad();
        await _aplicarLogicaNotificaciones();
      }
    } catch (e) {
      print('❌ Error al guardar configuración: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al guardar: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _aplicarLogicaPrioridad() async {
    if (!_prioridadUrgentes) return;

    try {
      print('🔄 Aplicando lógica de prioridad...');

      // Obtener todas las órdenes urgentes que no están entregadas
      final ordenesUrgentes = await supabase
          .from('ordenes')
          .select()
          .eq('es_urgente', true)
          .neq('estado', 'ENTREGADO')
          .order('fecha_creacion', ascending: true);

      print('📦 Órdenes urgentes encontradas: ${ordenesUrgentes.length}');

      // Aquí podrías implementar lógica adicional como:
      // - Reasignar repartidores
      // - Enviar notificaciones
      // - Actualizar prioridades en la base de datos

      if (_ordenarPorDistancia) {
        print('📍 Ordenamiento por distancia habilitado');
        // Implementar ordenamiento por geolocalización
      }

      if (_ordenarPorFecha) {
        print('📅 Ordenamiento por fecha habilitado');
        // Ya está ordenado por fecha_creacion
      }

      print('✅ Lógica de prioridad aplicada');
    } catch (e) {
      print('❌ Error al aplicar lógica de prioridad: $e');
    }
  }

  Future<void> _aplicarLogicaNotificaciones() async {
    try {
      print('🔔 Configurando notificaciones...');

      // Aquí implementarías la lógica de notificaciones
      // Por ejemplo, activar/desactivar webhooks, servicios de email, etc.

      if (_notificacionesEmail) {
        print('✉️ Notificaciones por email activadas');
      }

      if (_notificacionesSMS) {
        print('📱 Notificaciones por SMS activadas');
      }

      if (_notificacionesRepartidores) {
        print('🚚 Notificaciones para repartidores activadas');
      }

      print('✅ Configuración de notificaciones aplicada');
    } catch (e) {
      print('❌ Error al configurar notificaciones: $e');
    }
  }
}
