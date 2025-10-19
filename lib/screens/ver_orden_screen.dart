import 'package:flutter/material.dart';
import '../models/orden.dart';
import '../widgets/shared_layout.dart';

class VerOrdenScreen extends StatelessWidget {
  final Orden orden;

  const VerOrdenScreen({super.key, required this.orden});

  @override
  Widget build(BuildContext context) {
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
                Text(
                  'Detalles de la Orden #${orden.numeroOrden}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const Spacer(),
                if (orden.esUrgente)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'ORDEN URGENTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeccionInformacionGeneral(),
                      const SizedBox(height: 24),
                      _buildSeccionEmisor(),
                      const SizedBox(height: 24),
                      _buildSeccionDestinatario(),
                      const SizedBox(height: 24),
                      _buildSeccionEstadoYFechas(),
                      const SizedBox(height: 24),
                      _buildSeccionRepartidor(),
                      const SizedBox(height: 24),
                      _buildSeccionNotas(),
                      const SizedBox(height: 24),
                      if (orden.requierePago) ...[
                        _buildSeccionPago(),
                        const SizedBox(height: 24),
                      ],
                      _buildSeccionFotoEntrega(),
                      const SizedBox(height: 32),
                      _buildBotonAceptar(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionInformacionGeneral() {
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
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.info, color: Color(0xFF1976D2), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Número de Orden', '#${orden.numeroOrden}'),
              ),
              Expanded(
                child: _buildInfoItem('ID', orden.id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItemWithIcon('Estado', orden.estado, _getStatusIcon(orden.estado), _getStatusColor(orden.estado)),
              ),
              Expanded(
                child: _buildInfoItem('Tipo', orden.esUrgente ? 'Urgente' : 'Normal'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionEmisor() {
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
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person, color: Color(0xFF1976D2), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información del Emisor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem('Nombre', orden.emisor),
        ],
      ),
    );
  }

  Widget _buildSeccionDestinatario() {
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
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información del Destinatario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem('Nombre', orden.receptor),
          const SizedBox(height: 16),
          _buildInfoItem('Dirección', orden.direccionDestino),
        ],
      ),
    );
  }

  Widget _buildSeccionEstadoYFechas() {
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
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.schedule, color: Color(0xFFFF9800), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Estado y Fechas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInfoItemWithIcon('Estado Actual', orden.estado, _getStatusIcon(orden.estado), _getStatusColor(orden.estado)),
              ),
              Expanded(
                child: _buildInfoItem('Fecha de Creación', _formatDate(orden.fechaCreacion)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Fecha de Entrega', 
                  orden.fechaEntrega != null ? _formatDate(orden.fechaEntrega!) : 'No especificada'
                ),
              ),
              Expanded(
                child: _buildInfoItem('Descripción', orden.descripcion),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionRepartidor() {
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
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.delivery_dining, color: Color(0xFF9C27B0), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Repartidor Asignado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoItem('Repartidor', orden.repartidor ?? 'Sin asignar'),
        ],
      ),
    );
  }

  Widget _buildSeccionNotas() {
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
                  color: const Color(0xFF607D8B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.note, color: Color(0xFF607D8B), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notas Adicionales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Text(
              orden.notas?.isNotEmpty == true ? orden.notas! : 'Sin notas adicionales',
              style: TextStyle(
                fontSize: 14,
                color: orden.notas?.isNotEmpty == true 
                    ? const Color(0xFF2C2C2C) 
                    : const Color(0xFF999999),
                fontStyle: orden.notas?.isNotEmpty == true 
                    ? FontStyle.normal 
                    : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPago() {
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
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información de Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Monto a cobrar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: orden.pagado 
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: orden.pagado 
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orden.pagado ? 'PAGADO' : 'PENDIENTE DE PAGO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: orden.pagado 
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monto a cobrar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      orden.pagado ? Icons.check_circle : Icons.pending,
                      color: orden.pagado 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${orden.moneda == 'USD' ? '\$' : '\$'} ${orden.montoCobrar.toStringAsFixed(2)} ${orden.moneda}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: orden.pagado 
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información adicional
          _buildInfoItem('Moneda', orden.moneda == 'USD' ? 'Dólares (USD)' : 'Pesos Cubanos (CUP)'),
          
          if (orden.pagado && orden.fechaPago != null) ...[
            const SizedBox(height: 12),
            _buildInfoItem(
              'Fecha de pago', 
              '${orden.fechaPago!.day}/${orden.fechaPago!.month}/${orden.fechaPago!.year} ${orden.fechaPago!.hour}:${orden.fechaPago!.minute.toString().padLeft(2, '0')}'
            ),
          ],
          
          if (orden.notasPago != null && orden.notasPago!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoItem('Notas del pago', orden.notasPago!),
          ],
        ],
      ),
    );
  }

  Widget _buildSeccionFotoEntrega() {
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
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Foto de Entrega',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: orden.fotoEntrega != null && orden.fotoEntrega!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      orden.fotoEntrega!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderFoto();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                          ),
                        );
                      },
                    ),
                  )
                : _buildPlaceholderFoto(),
          ),
          if (orden.fotoEntrega != null && orden.fotoEntrega!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Foto de entrega registrada',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderFoto() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 48,
            color: const Color(0xFF999999),
          ),
          const SizedBox(height: 12),
          Text(
            orden.estado == 'ENTREGADO' 
                ? 'Sin foto de entrega'
                : 'Foto disponible al entregar',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (orden.estado != 'ENTREGADO') ...[
            const SizedBox(height: 4),
            const Text(
              'El repartidor tomará una foto al entregar',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBotonAceptar(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Aceptar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
        return Icons.info;
    }
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'ENTREGADO':
        return const Color(0xFF4CAF50); // Verde
      case 'EN TRANSITO':
        return const Color(0xFF2196F3); // Azul
      case 'POR ENVIAR':
        return const Color(0xFFFF9800); // Naranja
      case 'CANCELADA':
        return const Color(0xFF9E9E9E); // Gris
      case 'ATRASADO':
        return const Color(0xFFDC2626); // Rojo
      default:
        return const Color(0xFF666666); // Gris por defecto
    }
  }

  Widget _buildInfoItemWithIcon(String label, String value, IconData icon, Color color) {
    return Column(
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
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
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
