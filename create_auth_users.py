#!/usr/bin/env python3
"""
Script para crear usuarios en Firebase Authentication
"""

import firebase_admin
from firebase_admin import credentials, auth

# Inicializar Firebase Admin SDK
cred = credentials.Certificate('paqueteria-web-app-firebase-adminsdk-fbsvc-5846fb7c81.json')
firebase_admin.initialize_app(cred)

print("=" * 70)
print("🔐 CREANDO USUARIOS EN FIREBASE AUTHENTICATION")
print("=" * 70)
print()

# Usuarios a crear
usuarios = [
    {
        'email': 'admin@paqueteria.com',
        'password': 'Admin123!',
        'display_name': 'Administrador Principal',
        'rol': 'ADMINISTRADOR'
    },
    {
        'email': 'repartidor@paqueteria.com',
        'password': 'Rep123!',
        'display_name': 'Juan Repartidor',
        'rol': 'REPARTIDOR'
    }
]

for usuario in usuarios:
    try:
        user = auth.create_user(
            email=usuario['email'],
            password=usuario['password'],
            display_name=usuario['display_name']
        )
        print(f"✅ Usuario '{usuario['display_name']}' creado exitosamente")
        print(f"   📧 Email: {usuario['email']}")
        print(f"   🔑 Password: {usuario['password']}")
        print(f"   👤 Rol: {usuario['rol']}")
        print(f"   🆔 UID: {user.uid}")
        print()
    except auth.EmailAlreadyExistsError:
        print(f"ℹ️  Usuario '{usuario['email']}' ya existe")
        print(f"   📧 Email: {usuario['email']}")
        print(f"   🔑 Password: {usuario['password']}")
        print(f"   👤 Rol: {usuario['rol']}")
        print()
    except Exception as e:
        print(f"❌ Error creando '{usuario['email']}': {str(e)}")
        print()

print("=" * 70)
print("✅ PROCESO COMPLETADO")
print("=" * 70)
print()
print("🔐 Credenciales para login:")
print()
print("ADMINISTRADOR:")
print("  Email: admin@paqueteria.com")
print("  Password: Admin123!")
print()
print("REPARTIDOR:")
print("  Email: repartidor@paqueteria.com")
print("  Password: Rep123!")
print()

