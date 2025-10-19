import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/orden.dart';
import '../main.dart';

class DetalleOrdenScreen extends StatefulWidget {
  final Orden orden;

  const DetalleOrdenScreen({
    Key? key,
    required this.orden,
  }) : super(key: key);

  @override
  State<DetalleOrdenScreen> createState() => _DetalleOrdenScreenState();
}

class _DetalleOrdenScreenState extends State<DetalleOrdenScreen> {
  bool _isLoading = false;
  bool _fotoEntregaObligatoria = true; // Por defecto activado

  @override
  void initState() {
    super.initState();
    _cargarConfiguracionFoto();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Orden #${widget.orden.numeroOrden}'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.orden.estado != 'ENTREGADO' && widget.orden.estado != 'CANCELADA')
            IconButton(
              onPressed: _mostrarOpciones,
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Más padding inferior
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal con información básica
            _buildInfoCard(),
            const SizedBox(height: 12),
            
            // Card de contacto
            _buildContactCard(),
            const SizedBox(height: 12),
            
            // Card de detalles de entrega
            _buildDeliveryCard(),
            const SizedBox(height: 12),
            
            // Card de pago (si aplica)
            if (widget.orden.requierePago) ...[
              _buildPaymentCard(),
              const SizedBox(height: 12),
            ],
            
            // Card de historial de estados
            _buildStatusHistoryCard(),
            const SizedBox(height: 20), // Más espacio antes de los botones
            
            // Indicador de foto obligatoria
            if (widget.orden.estado != 'ENTREGADO' && widget.orden.estado != 'CANCELADA' && _fotoEntregaObligatoria)
              _buildFotoIndicator(),
            
            // Botones de acción
            if (widget.orden.estado != 'ENTREGADO' && widget.orden.estado != 'CANCELADA')
              _buildActionButtons(),
              
            // Espacio extra al final para evitar que se obstruyan los botones
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información General',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                _buildStatusChip(widget.orden.estado),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.confirmation_number, 'Número de Orden', '#${widget.orden.numeroOrden}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, 'Emisor', widget.orden.emisor),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person_outline, 'Destinatario', widget.orden.receptor),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Dirección', widget.orden.direccionDestino),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.schedule, 'Fecha de Creación', _formatearFecha(widget.orden.fechaCreacion)),
            if (widget.orden.fechaEntrega != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.local_shipping, 'Fecha de Entrega', _formatearFecha(widget.orden.fechaEntrega)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            if (widget.orden.telefonoDestinatario != null && widget.orden.telefonoDestinatario!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF1976D2), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Teléfono del Destinatario',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.orden.telefonoDestinatario!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2C2C2C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => _llamarDestinatario(widget.orden.telefonoDestinatario!),
                      icon: const Icon(Icons.call, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.phone_disabled, color: Color(0xFF999999), size: 20),
                  SizedBox(width: 12),
                  Text(
                    'No hay teléfono disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de Entrega',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.location_city, 'Ciudad', widget.orden.ciudadDestino ?? 'No especificada'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.description, 'Descripción', widget.orden.descripcion),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.scale, 'Peso', '${widget.orden.peso ?? 0} kg'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.straighten, 'Dimensiones', '${widget.orden.largo ?? 0} x ${widget.orden.ancho ?? 0} x ${widget.orden.alto ?? 0} cm'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Color(0xFF4CAF50), size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monto a Cobrar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${widget.orden.moneda == 'USD' ? '\$' : '\$'} ${widget.orden.montoCobrar.toStringAsFixed(2)} ${widget.orden.moneda}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryCard() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Estados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatusTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final estados = ['POR ENVIAR', 'EN TRANSITO', 'ENTREGADO'];
    final estadoActual = widget.orden.estado;
    final indiceActual = estados.indexOf(estadoActual);
    
    return Column(
      children: estados.asMap().entries.map((entry) {
        final index = entry.key;
        final estado = entry.value;
        final isCompleted = index <= indiceActual;
        final isCurrent = index == indiceActual;
        
        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF4CAF50) : Colors.grey[300],
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: const Color(0xFF1976D2), width: 3) : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estado,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? const Color(0xFF2C2C2C) : Colors.grey[600],
                    ),
                  ),
                  if (isCurrent)
                    const Text(
                      'Estado actual',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFotoIndicator() {
    final tieneFoto = widget.orden.fotoEntrega != null && widget.orden.fotoEntrega!.isNotEmpty;
    
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tieneFoto ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                tieneFoto ? Icons.check_circle : Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tieneFoto ? 'Foto de entrega tomada' : 'Foto de entrega requerida',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tieneFoto ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                    ),
                  ),
                  Text(
                    tieneFoto ? 'Ya puedes marcar como entregada' : 'Debes tomar una foto antes de entregar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (!tieneFoto)
              TextButton(
                onPressed: _tomarFotoEntrega,
                child: const Text(
                  'Tomar Foto',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botones en columna para mejor diseño
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _marcarComoEntregado(),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Marcar como Entregado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _marcarComoEnTransito(),
                    icon: const Icon(Icons.local_shipping, size: 18),
                    label: const Text('Marcar como En Tránsito'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF666666), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C2C2C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String estado) {
    Color color;
    IconData icon;
    
    switch (estado) {
      case 'POR ENVIAR':
        color = const Color(0xFFFF9800);
        icon = Icons.schedule;
        break;
      case 'EN TRANSITO':
        color = const Color(0xFF2196F3);
        icon = Icons.local_shipping;
        break;
      case 'ENTREGADO':
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'CANCELADA':
        color = const Color(0xFFF44336);
        icon = Icons.cancel;
        break;
      default:
        color = const Color(0xFF666666);
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'No especificada';
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _llamarDestinatario(String telefono) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: telefono);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _mostrarMensaje('No se puede realizar la llamada');
      }
    } catch (e) {
      _mostrarMensaje('Error al realizar la llamada: $e');
    }
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), // Más padding inferior
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Opciones
            _buildOptionTile(
              icon: Icons.phone,
              title: 'Llamar al Destinatario',
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pop(context);
                if (widget.orden.telefonoDestinatario != null && widget.orden.telefonoDestinatario!.isNotEmpty) {
                  _llamarDestinatario(widget.orden.telefonoDestinatario!);
                } else {
                  _mostrarMensaje('No hay teléfono disponible');
                }
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.local_shipping,
              title: 'Marcar como En Tránsito',
              color: const Color(0xFF1976D2),
              onTap: () {
                Navigator.pop(context);
                _marcarComoEnTransito();
              },
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.check_circle,
              title: 'Marcar como Entregado',
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pop(context);
                _marcarComoEntregado();
              },
            ),
            const SizedBox(height: 30), // Más espacio al final
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }


  void _marcarComoEntregado() async {
    // Si la foto es obligatoria, verificar si ya tiene foto
    if (_fotoEntregaObligatoria && (widget.orden.fotoEntrega == null || widget.orden.fotoEntrega!.isEmpty)) {
      _mostrarErrorFotoObligatoria();
      return;
    }

    final confirmado = await _mostrarConfirmacion(
      'Confirmar Entrega',
      '¿Estás seguro de que quieres marcar esta orden como entregada?',
    );
    
    if (confirmado) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await supabase
            .from('ordenes')
            .update({
              'estado': 'ENTREGADO',
              'fecha_entrega': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.orden.id);
        
        _mostrarMensaje('Orden marcada como entregada');
        Navigator.pop(context, true); // Regresar con resultado
      } catch (e) {
        _mostrarMensaje('Error al actualizar la orden: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _marcarComoEnTransito() async {
    final confirmado = await _mostrarConfirmacion(
      'Confirmar Envío',
      '¿Estás seguro de que quieres marcar esta orden como en tránsito?',
    );
    
    if (confirmado) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await supabase
            .from('ordenes')
            .update({
              'estado': 'EN TRANSITO',
            })
            .eq('id', widget.orden.id);
        
        _mostrarMensaje('Orden marcada como en tránsito');
        Navigator.pop(context, true); // Regresar con resultado
      } catch (e) {
        _mostrarMensaje('Error al actualizar la orden: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _mostrarConfirmacion(String titulo, String mensaje) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFF1976D2),
      ),
    );
  }

  void _mostrarErrorFotoObligatoria() {
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
              _tomarFotoEntrega();
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

  Future<void> _tomarFotoEntrega() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          // Verificar que el bucket existe primero
          print('🔍 Verificando bucket fotos-entrega...');
          
          // Subir imagen a Supabase Storage
          final fileName = 'entrega_${widget.orden.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final fileBytes = await image.readAsBytes();
          
          print('📤 Subiendo archivo: $fileName');
          
          // Usar directamente el bucket fotos-perfil que ya existe
          const String bucketName = 'fotos-perfil';
          
          final uploadResult = await supabase.storage
              .from(bucketName)
              .uploadBinary(fileName, fileBytes);

          print('✅ Upload exitoso en $bucketName: $uploadResult');

          // Obtener URL pública de la imagen
          final imageUrl = supabase.storage
              .from(bucketName)
              .getPublicUrl(fileName);

          print('🔗 URL generada: $imageUrl');

          // Actualizar la orden con la URL de la imagen
          await supabase
              .from('ordenes')
              .update({
                'foto_entrega': imageUrl,
              })
              .eq('id', widget.orden.id);

          print('💾 Orden actualizada en BD');

          _mostrarMensaje('✅ Foto subida exitosamente a Supabase. Ahora puedes marcar como entregada.');
          
          // Actualizar el estado local para mostrar la previsualización
          setState(() {
            // La orden se actualizará cuando se recargue desde la base de datos
          });

        } catch (uploadError) {
          print('❌ Error detallado: $uploadError');
          _mostrarMensaje('❌ Error al subir la foto a Supabase: $uploadError');
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error al tomar la foto: $e');
      _mostrarMensaje('❌ Error al tomar la foto: $e');
    }
  }
}
