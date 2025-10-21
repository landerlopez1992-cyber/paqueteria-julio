import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/orden.dart';
import '../config/app_colors.dart';
import '../main.dart';

class OrdenPrintModal extends StatefulWidget {
  final Orden orden;

  const OrdenPrintModal({
    super.key,
    required this.orden,
  });

  @override
  State<OrdenPrintModal> createState() => _OrdenPrintModalState();
}

class _OrdenPrintModalState extends State<OrdenPrintModal> {
  bool _isLoading = true;
  bool _incluirQR = true;
  bool _incluirDatosDestinatario = true;
  bool _incluirNumeroOrden = true;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final response = await supabase
          .from('configuracion_envios')
          .select('incluir_qr, incluir_datos_destinatario, incluir_numero_orden')
          .limit(1)
          .single();

      if (mounted) {
        setState(() {
          _incluirQR = response['incluir_qr'] ?? true;
          _incluirDatosDestinatario = response['incluir_datos_destinatario'] ?? true;
          _incluirNumeroOrden = response['incluir_numero_orden'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar configuración de impresión: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 200),
          padding: const EdgeInsets.all(40),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 20),
              Text(
                'Cargando configuración...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                              if (_incluirNumeroOrden) ...[
                                Text(
                                  'Orden #${widget.orden.id}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                'Fecha: ${_formatFecha(widget.orden.fechaCreacion)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Código QR (solo si está habilitado)
                        if (_incluirQR)
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
                                  data: widget.orden.id, // El ID de la orden es único
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
                        _buildInfoRow('Nombre:', widget.orden.emisor),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información del Destinatario (solo si está habilitado)
                    if (_incluirDatosDestinatario)
                      _buildSeccion(
                        'Destinatario',
                        [
                          _buildInfoRow('Nombre:', widget.orden.receptor),
                          _buildInfoRow('Teléfono:', widget.orden.telefonoDestinatario ?? 'N/A'),
                          _buildInfoRow('Dirección:', widget.orden.direccionDestino),
                          if (widget.orden.ciudadDestino != null)
                            _buildInfoRow('Ciudad:', widget.orden.ciudadDestino!),
                          if (widget.orden.provinciaDestino != null)
                            _buildInfoRow('Provincia:', widget.orden.provinciaDestino!),
                        ],
                      ),
                    
                    if (_incluirDatosDestinatario)
                      const SizedBox(height: 20),
                    
                    const SizedBox(height: 20),
                    
                    // Detalles del paquete
                    _buildSeccion(
                      'Detalles del Paquete',
                      [
                        _buildInfoRow('Descripción:', widget.orden.descripcion),
                        if (widget.orden.cantidadBultos != null)
                          _buildInfoRow('Cantidad de bultos:', '${widget.orden.cantidadBultos}'),
                        if (widget.orden.peso != null)
                          _buildInfoRow('Peso:', '${widget.orden.peso} lb'),
                        if (widget.orden.notas != null && widget.orden.notas!.isNotEmpty)
                          _buildInfoRow('Notas:', widget.orden.notas!),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información de entrega
                    _buildSeccion(
                      'Información de Entrega',
                      [
                        _buildInfoRow('Estado:', widget.orden.estado),
                        if (widget.orden.fechaEntrega != null)
                          _buildInfoRow('Fecha de entrega:', _formatFecha(widget.orden.fechaEntrega!)),
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

  String _formatFechaCorta(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  Future<void> _imprimir(BuildContext context) async {
    try {
      // Generar el PDF
      final pdf = await _generarPDF();
      final pdfBytes = await pdf.save();
      
      if (kIsWeb) {
        // Fallback en web: intentar abrir diálogo nativo si está disponible
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Orden_${widget.orden.numeroOrden}.pdf',
        );
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Para MÓVIL/DESKTOP: Usar printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Orden_${widget.orden.numeroOrden}.pdf',
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
      }
    } catch (e) {
      print('Error al imprimir: $e');
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
    
    // Generar el código QR como imagen (solo si está habilitado)
    final qrImageBytes = _incluirQR ? await _generarQRBytes() : null;

    // Formato 4x6 pulgadas para etiquetas térmicas (estándar de paquetería)
    // 288 puntos x 432 puntos (72 DPI)
    final labelFormat = PdfPageFormat(
      4 * PdfPageFormat.inch,  // 4 pulgadas de ancho
      6 * PdfPageFormat.inch,  // 6 pulgadas de alto
      marginAll: 0.15 * PdfPageFormat.inch, // Márgenes pequeños
    );

    pdf.addPage(
      pw.Page(
        pageFormat: labelFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header compacto
              pw.Text(
                'J ALVAREZ EXPRESS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              
              // Número de orden (solo si está habilitado)
              if (_incluirNumeroOrden) ...[
                pw.Text(
                  '#${widget.orden.numeroOrden}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
              
              // CÓDIGO QR GRANDE - Prioritario (solo si está habilitado)
              if (_incluirQR && qrImageBytes != null) ...[
                pw.Container(
                  width: 180,  // QR más grande para fácil escaneo
                  height: 180,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2),
                  ),
                  child: pw.Image(pw.MemoryImage(qrImageBytes)),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'ESCANEAR PARA VERIFICAR',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 10),
              ],
              
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 6),
              
              // Destinatario - INFORMACIÓN MÁS IMPORTANTE (solo si está habilitado)
              if (_incluirDatosDestinatario)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PARA:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        widget.orden.receptor.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        maxLines: 2,
                      ),
                      if (widget.orden.telefonoDestinatario != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Tel: ${widget.orden.telefonoDestinatario}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                      pw.SizedBox(height: 2),
                      pw.Text(
                        widget.orden.direccionDestino,
                        style: const pw.TextStyle(fontSize: 9),
                        maxLines: 2,
                      ),
                      // Provincia y Municipio
                      if (widget.orden.provinciaDestino != null || widget.orden.municipioDestino != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${widget.orden.municipioDestino ?? ''}, ${widget.orden.provinciaDestino ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                      // Ciudad (si existe y es diferente)
                      if (widget.orden.ciudadDestino != null && widget.orden.ciudadDestino != widget.orden.municipioDestino) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          widget.orden.ciudadDestino!,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ],
                  ),
                ),
              
              if (_incluirDatosDestinatario)
                pw.SizedBox(height: 6),
              
              pw.SizedBox(height: 6),
              
              // Emisor - Compacto
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DE: ${widget.orden.emisor}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 6),
              
              // Detalles del paquete - Compacto
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  if (widget.orden.cantidadBultos != null)
                    pw.Column(
                      children: [
                        pw.Text(
                          'BULTOS',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.Text(
                          '${widget.orden.cantidadBultos}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (widget.orden.peso != null)
                    pw.Column(
                      children: [
                        pw.Text(
                          'PESO',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                        pw.Text(
                          '${widget.orden.peso} lb',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'ESTADO',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                      pw.Text(
                        widget.orden.estado,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 6),
              
              // Fecha de entrega si existe
              if (widget.orden.fechaEntrega != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1),
                  ),
                  child: pw.Text(
                    'ENTREGAR: ${_formatFechaCorta(widget.orden.fechaEntrega!)}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
              
              pw.Spacer(),
              
              // Pie de página minimalista
              pw.Text(
                'Impreso: ${_formatFechaCorta(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 6),
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
        data: widget.orden.id,
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

