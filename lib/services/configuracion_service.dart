import '../main.dart';

class ConfiguracionService {
  // Singleton
  static final ConfiguracionService _instance = ConfiguracionService._internal();
  factory ConfiguracionService() => _instance;
  ConfiguracionService._internal();

  // Cache de configuración
  Map<String, dynamic>? _config;
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obtiene la configuración (usa cache si está disponible)
  Future<Map<String, dynamic>> obtenerConfiguracion({bool forceRefresh = false}) async {
    // Si hay cache válido y no se fuerza refresh, retornar cache
    if (!forceRefresh && 
        _config != null && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      print('📦 Usando configuración en cache');
      return _config!;
    }

    try {
      print('🔄 Obteniendo configuración desde Supabase...');
      
      final response = await supabase
          .from('configuracion_envios')
          .select()
          .limit(1)
          .single();

      _config = response;
      _lastFetch = DateTime.now();
      
      print('✅ Configuración obtenida y cacheada');
      return _config!;
    } catch (e) {
      print('❌ Error al obtener configuración: $e');
      // Si hay cache antiguo, retornarlo como fallback
      if (_config != null) {
        print('⚠️ Usando configuración en cache (antigua)');
        return _config!;
      }
      rethrow;
    }
  }

  /// Verifica si las órdenes urgentes tienen prioridad
  Future<bool> tienenPrioridadUrgentes() async {
    final config = await obtenerConfiguracion();
    return config['prioridad_urgentes'] ?? true;
  }

  /// Obtiene el tipo de impresión configurado
  Future<String> obtenerTipoImpresion() async {
    final config = await obtenerConfiguracion();
    return config['tipo_impresion'] ?? 'etiqueta_completa';
  }

  /// Verifica si se debe mostrar rastreo a usuarios
  Future<bool> mostrarRastreoUsuarios() async {
    final config = await obtenerConfiguracion();
    return config['mostrar_rastreo_usuarios'] ?? true;
  }

  /// Verifica si las notificaciones están habilitadas para un tipo de usuario
  Future<bool> notificacionesHabilitadas(String tipo) async {
    final config = await obtenerConfiguracion();
    switch (tipo) {
      case 'emisores':
        return config['notificaciones_emisores'] ?? true;
      case 'destinatarios':
        return config['notificaciones_destinatarios'] ?? false;
      case 'repartidores':
        return config['notificaciones_repartidores'] ?? true;
      default:
        return false;
    }
  }

  /// Verifica si las notificaciones por email están habilitadas
  Future<bool> notificacionesEmailHabilitadas() async {
    final config = await obtenerConfiguracion();
    return config['notificaciones_email'] ?? true;
  }

  /// Verifica si las notificaciones por SMS están habilitadas
  Future<bool> notificacionesSMSHabilitadas() async {
    final config = await obtenerConfiguracion();
    return config['notificaciones_sms'] ?? false;
  }

  /// Verifica si la foto de entrega es obligatoria
  Future<bool> esFotoEntregaObligatoria() async {
    final config = await obtenerConfiguracion();
    return config['foto_entrega_obligatoria'] ?? true;
  }

  /// Verifica si la confirmación de entrega es obligatoria
  Future<bool> esConfirmacionEntregaObligatoria() async {
    final config = await obtenerConfiguracion();
    return config['confirmacion_entrega'] ?? true;
  }

  /// Verifica si la firma digital es obligatoria
  Future<bool> esFirmaDigitalObligatoria() async {
    final config = await obtenerConfiguracion();
    return config['firma_digital'] ?? false;
  }

  /// Obtiene el radio de entrega en metros
  Future<double> obtenerRadioEntrega() async {
    final config = await obtenerConfiguracion();
    return (config['radio_entrega'] ?? 100.0).toDouble();
  }

  /// Verifica si la geolocalización es obligatoria
  Future<bool> esGeolocalizacionObligatoria() async {
    final config = await obtenerConfiguracion();
    return config['geolocalizacion_obligatoria'] ?? true;
  }

  /// Obtiene el intervalo de actualización del rastreo en segundos
  Future<int> obtenerIntervaloActualizacionRastreo() async {
    final config = await obtenerConfiguracion();
    return config['intervalo_actualizacion'] ?? 30;
  }

  /// Obtiene el tiempo de espera en entrega en minutos
  Future<int> obtenerTiempoEsperaEntrega() async {
    final config = await obtenerConfiguracion();
    return config['tiempo_espera_entrega'] ?? 15;
  }

  /// Limpia el cache de configuración
  void limpiarCache() {
    _config = null;
    _lastFetch = null;
    print('🗑️ Cache de configuración limpiado');
  }

  /// Obtiene las opciones de impresión según la configuración
  Future<Map<String, bool>> obtenerOpcionesImpresion() async {
    final config = await obtenerConfiguracion();
    return {
      'incluir_qr': config['incluir_qr'] ?? true,
      'incluir_datos_destinatario': config['incluir_datos_destinatario'] ?? true,
      'incluir_numero_orden': config['incluir_numero_orden'] ?? true,
    };
  }

  /// Obtiene el criterio de ordenamiento de órdenes
  Future<Map<String, bool>> obtenerCriteriosOrdenamiento() async {
    final config = await obtenerConfiguracion();
    return {
      'por_fecha': config['ordenar_por_fecha'] ?? false,
      'por_distancia': config['ordenar_por_distancia'] ?? true,
      'prioridad_urgentes': config['prioridad_urgentes'] ?? true,
    };
  }
}



