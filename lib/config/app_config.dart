import 'package:flutter/foundation.dart';

class AppConfig {
  // Detectar si la app está corriendo en móvil
  static bool get isMobile {
    if (kIsWeb) {
      // En web, detectar por el tamaño de pantalla
      return false; // Por defecto web es desktop
    } else {
      // En móvil nativo, siempre es móvil
      return true;
    }
  }

  // Detectar si es web
  static bool get isWeb => kIsWeb;

  // Detectar si es desktop
  static bool get isDesktop => kIsWeb;

  // Obtener el tipo de plataforma
  static String get platformType {
    if (kIsWeb) {
      return 'web';
    } else {
      return 'mobile';
    }
  }
}


