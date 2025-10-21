import 'package:flutter/material.dart';
import '../main.dart';
import '../models/orden.dart';
import 'detalle_orden_screen.dart';

class QRScannerSimpleScreen extends StatefulWidget {
  const QRScannerSimpleScreen({super.key});

  @override
  State<QRScannerSimpleScreen> createState() => _QRScannerSimpleScreenState();
}

class _QRScannerSimpleScreenState extends State<QRScannerSimpleScreen> {
  final TextEditingController _qrController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _procesarQR(String qrCode) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 QR escaneado: $qrCode');

      // Buscar la orden por ID
      final response = await supabase
          .from('ordenes')
          .select('*')
          .eq('id', qrCode)
          .single();

      print('✅ Orden encontrada: ${response['numero_orden']}');

      final orden = Orden.fromJson(response);

      // Navegar a la pantalla de detalles
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DetalleOrdenScreen(orden: orden),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al buscar orden: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró la orden: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Escanear Orden',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF37474F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de QR
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),

            // Título
            const Text(
              'Escanear Código QR',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            const Text(
              'Ingresa manualmente el código QR de la orden o usa la cámara para escanearlo automáticamente.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Campo de entrada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _qrController,
                decoration: const InputDecoration(
                  hintText: 'Pega aquí el código QR de la orden',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.qr_code, color: Color(0xFF4CAF50)),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _procesarQR(value.trim());
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Botón de buscar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () {
                  if (_qrController.text.trim().isNotEmpty) {
                    _procesarQR(_qrController.text.trim());
                  }
                },
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search, size: 20),
                label: Text(_isLoading ? 'Buscando...' : 'Buscar Orden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botón de usar cámara (deshabilitado por ahora)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de cámara temporalmente deshabilitada'),
                      backgroundColor: Color(0xFF666666),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text('Usar Cámara'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                  side: const BorderSide(color: Color(0xFF666666)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
