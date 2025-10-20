import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  Future<void> _imprimir(BuildContext context) async {
    try {
      // Generar el PDF
      final pdf = await _generarPDF();
      
      // Abrir diálogo de impresión del sistema
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Orden_${orden.numeroOrden}.pdf',
      );
      
      if (context.mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento listo para imprimir'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al preparar impresión: $e'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<pw.Document> _generarPDF() async {
    final pdf = pw.Document();
    
    // Generar el código QR como imagen
    final qrImageBytes = await _generarQRBytes();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header con logo y QR
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Sistema de Paquetería',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Orden #${orden.numeroOrden}',
                        style: const pw.TextStyle(fontSize: 16),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Fecha: ${_formatFecha(orden.fechaCreacion)}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  // Código QR
                  if (qrImageBytes != null)
                    pw.Container(
                      width: 120,
                      height: 120,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 3),
                      ),
                      child: pw.Image(pw.MemoryImage(qrImageBytes)),
                    ),
                ],
              ),
              
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 24),
              
              // Emisor
              _buildPDFSeccion('Emisor', [
                _buildPDFInfoRow('Nombre:', orden.emisor),
              ]),
              
              pw.SizedBox(height: 20),
              
              // Destinatario
              _buildPDFSeccion('Destinatario', [
                _buildPDFInfoRow('Nombre:', orden.receptor),
                if (orden.telefonoDestinatario != null)
                  _buildPDFInfoRow('Teléfono:', orden.telefonoDestinatario!),
                _buildPDFInfoRow('Dirección:', orden.direccionDestino),
                if (orden.ciudadDestino != null)
                  _buildPDFInfoRow('Ciudad:', orden.ciudadDestino!),
                if (orden.provinciaDestino != null)
                  _buildPDFInfoRow('Provincia:', orden.provinciaDestino!),
              ]),
              
              pw.SizedBox(height: 20),
              
              // Detalles del paquete
              _buildPDFSeccion('Detalles del Paquete', [
                _buildPDFInfoRow('Descripción:', orden.descripcion),
                if (orden.cantidadBultos != null)
                  _buildPDFInfoRow('Cantidad de bultos:', '${orden.cantidadBultos}'),
                if (orden.peso != null)
                  _buildPDFInfoRow('Peso:', '${orden.peso} lb'),
                if (orden.notas != null && orden.notas!.isNotEmpty)
                  _buildPDFInfoRow('Notas:', orden.notas!),
              ]),
              
              pw.SizedBox(height: 20),
              
              // Información de entrega
              _buildPDFSeccion('Información de Entrega', [
                _buildPDFInfoRow('Estado:', orden.estado),
                if (orden.fechaEntrega != null)
                  _buildPDFInfoRow('Fecha de entrega:', _formatFecha(orden.fechaEntrega!)),
              ]),
              
              pw.Spacer(),
              
              // Pie de página
              pw.Column(
                children: [
                  pw.Divider(),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Gracias por confiar en nosotros',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Impreso: ${_formatFecha(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<Uint8List?> _generarQRBytes() async {
    try {
      // Generar QR como imagen para PDF
      final qrValidationResult = QrValidator.validate(
        data: orden.id,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode;
        final painter = QrPainter.withQr(
          qr: qrCode!,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );
        
        final image = await painter.toImageData(200);
        return image?.buffer.asUint8List();
      }
    } catch (e) {
      print('Error generando QR: $e');
    }
    return null;
  }

  pw.Widget _buildPDFSeccion(String titulo, List<pw.Widget> contenido) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: PdfColors.grey300,
          child: pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: contenido,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }
}

