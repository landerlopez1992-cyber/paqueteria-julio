import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? fotoUrl;
  final String nombre;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const ProfileAvatar({
    super.key,
    this.fotoUrl,
    required this.nombre,
    this.radius = 20,
    this.backgroundColor = const Color(0xFF4CAF50),
    this.textColor = Colors.white,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay foto URL, mostrar la imagen
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(fotoUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // Si falla la carga de la imagen, mostrar iniciales
          debugPrint('Error cargando foto de perfil: $exception');
        },
        child: fotoUrl == null || fotoUrl!.isEmpty
            ? _buildInitials()
            : null,
      );
    }
    
    // Si no hay foto, mostrar iniciales
    return _buildInitials();
  }

  Widget _buildInitials() {
    final inicial = nombre.isNotEmpty 
        ? nombre.substring(0, 1).toUpperCase()
        : 'U';
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        inicial,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
