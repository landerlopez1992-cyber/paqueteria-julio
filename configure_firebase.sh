#!/bin/bash

# Script de configuración automática de Firebase para Flutter
# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🔥 Configuración Automática de Firebase para Flutter      ║"
echo "║              Sistema de Paquetería - Web App                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: No se encuentra pubspec.yaml${NC}"
    echo "Por favor, ejecuta este script desde el directorio del proyecto Flutter"
    exit 1
fi

echo -e "${YELLOW}📋 Por favor, completa los siguientes datos de Firebase Console:${NC}"
echo -e "${YELLOW}   (Los puedes encontrar en: https://console.firebase.google.com/)${NC}"
echo ""

# Solicitar datos de Firebase
read -p "📝 API Key: " API_KEY
read -p "📝 Auth Domain: " AUTH_DOMAIN
read -p "📝 Project ID: " PROJECT_ID
read -p "📝 Storage Bucket: " STORAGE_BUCKET
read -p "📝 Messaging Sender ID: " MESSAGING_SENDER_ID
read -p "📝 App ID: " APP_ID

echo ""
echo -e "${BLUE}🔧 Instalando dependencias de Firebase...${NC}"

# Instalar FlutterFire CLI
echo -e "${YELLOW}Instalando FlutterFire CLI...${NC}"
dart pub global activate flutterfire_cli

# Agregar dependencias de Firebase
echo -e "${YELLOW}Agregando paquetes de Firebase a pubspec.yaml...${NC}"
flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add firebase_auth

echo ""
echo -e "${GREEN}✅ Dependencias instaladas correctamente${NC}"

# Crear archivo de configuración
echo ""
echo -e "${BLUE}📝 Creando archivo de configuración...${NC}"

mkdir -p lib/config

cat > lib/config/firebase_config.dart << EOF
// Configuración de Firebase
// ⚠️ NO SUBAS ESTE ARCHIVO A REPOSITORIOS PÚBLICOS

class FirebaseConfig {
  static const String apiKey = "$API_KEY";
  static const String authDomain = "$AUTH_DOMAIN";
  static const String projectId = "$PROJECT_ID";
  static const String storageBucket = "$STORAGE_BUCKET";
  static const String messagingSenderId = "$MESSAGING_SENDER_ID";
  static const String appId = "$APP_ID";
}
EOF

# Crear archivo de inicialización de Firebase
cat > lib/config/firebase_options.dart << EOF
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'firebase_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: FirebaseConfig.apiKey,
    authDomain: FirebaseConfig.authDomain,
    projectId: FirebaseConfig.projectId,
    storageBucket: FirebaseConfig.storageBucket,
    messagingSenderId: FirebaseConfig.messagingSenderId,
    appId: FirebaseConfig.appId,
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: FirebaseConfig.apiKey,
    authDomain: FirebaseConfig.authDomain,
    projectId: FirebaseConfig.projectId,
    storageBucket: FirebaseConfig.storageBucket,
    messagingSenderId: FirebaseConfig.messagingSenderId,
    appId: FirebaseConfig.appId,
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: FirebaseConfig.apiKey,
    authDomain: FirebaseConfig.authDomain,
    projectId: FirebaseConfig.projectId,
    storageBucket: FirebaseConfig.storageBucket,
    messagingSenderId: FirebaseConfig.messagingSenderId,
    appId: FirebaseConfig.appId,
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: FirebaseConfig.apiKey,
    authDomain: FirebaseConfig.authDomain,
    projectId: FirebaseConfig.projectId,
    storageBucket: FirebaseConfig.storageBucket,
    messagingSenderId: FirebaseConfig.messagingSenderId,
    appId: FirebaseConfig.appId,
  );
}
EOF

echo -e "${GREEN}✅ Archivos de configuración creados${NC}"

# Agregar firebase_config.dart a .gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "lib/config/firebase_config.dart" .gitignore; then
        echo "" >> .gitignore
        echo "# Firebase Config (contiene credenciales sensibles)" >> .gitignore
        echo "lib/config/firebase_config.dart" >> .gitignore
        echo -e "${GREEN}✅ firebase_config.dart agregado a .gitignore${NC}"
    fi
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    ✅ CONFIGURACIÓN COMPLETA                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}🎉 Firebase ha sido configurado correctamente!${NC}"
echo ""
echo -e "${YELLOW}📌 Próximos pasos:${NC}"
echo -e "   1. Verifica que las colecciones existan en Firebase Console:"
echo -e "      - emisores"
echo -e "      - receptores"
echo -e "      - ordenes"
echo ""
echo -e "   2. Ejecuta la aplicación:"
echo -e "      ${BLUE}flutter run -d chrome${NC}"
echo ""
echo -e "${YELLOW}📚 Archivos creados:${NC}"
echo -e "   - lib/config/firebase_config.dart"
echo -e "   - lib/config/firebase_options.dart"
echo ""
echo -e "${RED}⚠️  IMPORTANTE:${NC}"
echo -e "   ${RED}NO COMPARTAS el archivo firebase_config.dart${NC}"
echo -e "   ${RED}Ya está agregado a .gitignore${NC}"
echo ""



