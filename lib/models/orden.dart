class Orden {
  final String id;
  final String numeroOrden; // Nuevo campo para el número de orden
  final String emisor;
  final String receptor;
  final String descripcion;
  final String direccionDestino;
  String estado;
  final DateTime fechaCreacion;
  DateTime? fechaEntrega;
  final String? notas;
  final String? repartidor;
  final bool esUrgente;
  final String? fotoEntrega;
  
  // Campos de pago
  final bool requierePago;
  final double montoCobrar;
  final String moneda; // 'USD' o 'CUP'
  bool pagado;
  final DateTime? fechaPago;
  final String? notasPago;

  Orden({
    required this.id,
    required this.numeroOrden,
    required this.emisor,
    required this.receptor,
    required this.descripcion,
    required this.direccionDestino,
    required this.estado,
    required this.fechaCreacion,
    this.fechaEntrega,
    this.notas,
    this.repartidor,
    this.esUrgente = false,
    this.fotoEntrega,
    this.requierePago = false,
    this.montoCobrar = 0.0,
    this.moneda = 'CUP',
    this.pagado = false,
    this.fechaPago,
    this.notasPago,
  });

  // Convertir de JSON a Orden (útil para bases de datos Supabase)
  factory Orden.fromJson(Map<String, dynamic> json) {
    return Orden(
      id: json['id'].toString(),
      numeroOrden: json['numero_orden'] ?? 'N/A',
      emisor: json['emisor_nombre'] ?? 'Sin emisor',
      receptor: json['destinatario_nombre'] ?? 'Sin destinatario',
      descripcion: json['descripcion'] ?? '',
      direccionDestino: json['direccion_destino'] ?? '',
      estado: json['estado'] ?? 'POR ENVIAR',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      fechaEntrega: json['fecha_entrega'] != null 
          ? DateTime.parse(json['fecha_entrega'])
          : null,
      notas: json['notas'],
      repartidor: json['repartidor_nombre'],
      esUrgente: json['es_urgente'] ?? false,
      fotoEntrega: json['foto_entrega'],
      requierePago: json['requiere_pago'] ?? false,
      montoCobrar: (json['monto_cobrar'] ?? 0.0).toDouble(),
      moneda: json['moneda'] ?? 'CUP',
      pagado: json['pagado'] ?? false,
      fechaPago: json['fecha_pago'] != null 
          ? DateTime.parse(json['fecha_pago'])
          : null,
      notasPago: json['notas_pago'],
    );
  }

  // Convertir de Orden a JSON (útil para guardar en bases de datos)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeroOrden': numeroOrden,
      'emisor': emisor,
      'receptor': receptor,
      'descripcion': descripcion,
      'direccionDestino': direccionDestino,
      'estado': estado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaEntrega': fechaEntrega?.toIso8601String(),
      'notas': notas,
      'repartidor': repartidor,
      'esUrgente': esUrgente,
      'fotoEntrega': fotoEntrega,
      'requierePago': requierePago,
      'montoCobrar': montoCobrar,
      'moneda': moneda,
      'pagado': pagado,
      'fechaPago': fechaPago?.toIso8601String(),
      'notasPago': notasPago,
    };
  }
}

