import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../main.dart';
import '../models/orden.dart';
import 'detalle_orden_screen.dart';

class QRScannerFullscreen extends StatefulWidget {
  const QRScannerFullscreen({super.key});

  @override
  State<QRScannerFullscreen> createState() => _QRScannerFullscreenState();
}

class _QRScannerFullscreenState extends State<QRScannerFullscreen> {
  late final MobileScannerController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    for (final b in barcodes) {
      final value = b.rawValue;
      if (value != null && value.isNotEmpty) {
        _handled = true;
        try {
          final data = await supabase.from('ordenes').select('*').eq('id', value).single();
          if (!mounted) return;
          final orden = Orden.fromJson(data);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DetalleOrdenScreen(orden: orden)),
          );
        } catch (e) {
          _handled = false;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró la orden: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double frameSize = size.width * 0.72;
    final double left = (size.width - frameSize) / 2;
    final double top = (size.height - frameSize) / 2;
    final double labelTop = top > 56 ? top - 60 : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cámara de fondo
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),

          // Overlay oscuro con recorte transparente en el centro
          IgnorePointer(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                scanAreaRect: Rect.fromLTWH(left, top, frameSize, frameSize),
                borderRadius: 16,
              ),
              child: Container(),
            ),
          ),

          // Marco central verde
          IgnorePointer(
            child: Center(
              child: Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4CAF50), width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // Mira telescópica (cruz central)
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: frameSize,
                height: frameSize,
                child: Stack(
                  children: [
                    // Línea horizontal
                    Center(
                      child: Container(
                        width: 60,
                        height: 1,
                        color: const Color(0xFF4CAF50).withOpacity(0.8),
                      ),
                    ),
                    // Línea vertical
                    Center(
                      child: Container(
                        width: 1,
                        height: 60,
                        color: const Color(0xFF4CAF50).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Texto sobre el marco
          Positioned(
            left: 0,
            right: 0,
            top: labelTop,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Escanea el paquete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),



          // Botones inferiores (Cerrar y Flash)
          Positioned(
            left: 24,
            right: 24,
            top: top + frameSize + 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Flash
                ElevatedButton.icon(
                  onPressed: () => _controller.toggleTorch(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37474F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text('Flash'),
                ),
                // Botón Cerrar
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter para crear overlay oscuro con área transparente en el centro
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanAreaRect;
  final double borderRadius;

  _ScannerOverlayPainter({
    required this.scanAreaRect,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        scanAreaRect,
        Radius.circular(borderRadius),
      ));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.90),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

