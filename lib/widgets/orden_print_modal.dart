import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/orden.dart';
import '../config/app_colors.dart';

class OrdenPrintModal extends StatelessWidget {
  final Orden orden;

  const OrdenPrintModal({
    super.key,
    required this.orden,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF37474F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comprobante de Orden',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Contenido imprimible
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo y código QR en la misma fila
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información de la empresa
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sistema de Paquetería',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF37474F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Orden #${orden.id}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fecha: ${_formatFecha(orden.fechaCreacion)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Código QR
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF4CAF50), width: 3),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: orden.id, // El ID de la orden es único
                                version: QrVersions.auto,
                                size: 120,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF37474F),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF37474F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Escanear para verificar',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF4CAF50), thickness: 2),
                    const SizedBox(height: 24),
                    
                    // Información del Emisor
                    _buildSeccion(
                      'Emisor',
                      [
                        _buildInfoRow('Nombre:', orden.emisor),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información del Destinatario
                    _buildSeccion(
                      'Destinatario',
                      [
                        _buildInfoRow('Nombre:', orden.receptor),
                        _buildInfoRow('Teléfono:', orden.telefonoDestinatario ?? 'N/A'),
                        _buildInfoRow('Dirección:', orden.direccionDestino),
                        if (orden.ciudadDestino != null)
                          _buildInfoRow('Ciudad:', orden.ciudadDestino!),
                        if (orden.provinciaDestino != null)
                          _buildInfoRow('Provincia:', orden.provinciaDestino!),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Detalles del paquete
                    _buildSeccion(
                      'Detalles del Paquete',
                      [
                        _buildInfoRow('Descripción:', orden.descripcion),
                        if (orden.cantidadBultos != null)
                          _buildInfoRow('Cantidad de bultos:', '${orden.cantidadBultos}'),
                        if (orden.peso != null)
                          _buildInfoRow('Peso:', '${orden.peso} lb'),
                        if (orden.notas != null && orden.notas!.isNotEmpty)
                          _buildInfoRow('Notas:', orden.notas!),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información de entrega
                    _buildSeccion(
                      'Información de Entrega',
                      [
                        _buildInfoRow('Estado:', orden.estado),
                        if (orden.fechaEntrega != null)
                          _buildInfoRow('Fecha de entrega:', _formatFecha(orden.fechaEntrega!)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Pie de página
                    Center(
                      child: Column(
                        children: [
                          const Divider(color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 12),
                          const Text(
                            'Gracias por confiar en nosotros',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Impreso: ${_formatFecha(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Botones de acción
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _imprimir(context),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Imprimir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> contenido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
            children: contenido,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _imprimir(BuildContext context) {
    // Implementar lógica de impresión
    // Por ahora, simplemente llamar a window.print() en web
    Navigator.of(context).pop();
    
    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparando impresión...'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
    
    // TODO: Implementar impresión real usando printing package si es necesario
  }
}

