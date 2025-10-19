#!/usr/bin/env python3
"""
Script para crear las colecciones de Firestore automáticamente
con datos de ejemplo para el sistema de paquetería
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

# Inicializar Firebase Admin SDK
cred = credentials.Certificate('paqueteria-web-app-firebase-adminsdk-fbsvc-5846fb7c81.json')
firebase_admin.initialize_app(cred)

# Obtener referencia a Firestore
db = firestore.client()

print("🔥 Conectando a Firebase...")
print("✅ Conexión exitosa!")
print()

# Crear colección de EMISORES
print("📦 Creando colección 'emisores'...")
emisores_data = [
    {
        'nombre': 'Juan Pérez',
        'telefono': '555-1234',
        'direccion': 'Calle A #100',
        'email': 'juan@email.com',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Carlos Ruiz',
        'telefono': '555-5678',
        'direccion': 'Avenida B #200',
        'email': 'carlos@email.com',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Pedro López',
        'telefono': '555-9012',
        'direccion': 'Calle C #300',
        'email': 'pedro@email.com',
        'createdAt': firestore.SERVER_TIMESTAMP
    }
]

for emisor in emisores_data:
    db.collection('emisores').add(emisor)
    print(f"   ✓ Emisor '{emisor['nombre']}' creado")

print()

# Crear colección de RECEPTORES
print("📬 Creando colección 'receptores'...")
receptores_data = [
    {
        'nombre': 'María González',
        'telefono': '555-3456',
        'direccion': 'Calle X #400',
        'email': 'maria@email.com',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Ana Martínez',
        'telefono': '555-7890',
        'direccion': 'Avenida Y #500',
        'email': 'ana@email.com',
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Laura García',
        'telefono': '555-2345',
        'direccion': 'Calle Z #600',
        'email': 'laura@email.com',
        'createdAt': firestore.SERVER_TIMESTAMP
    }
]

for receptor in receptores_data:
    db.collection('receptores').add(receptor)
    print(f"   ✓ Receptor '{receptor['nombre']}' creado")

print()

# Crear colección de ÓRDENES
print("📋 Creando colección 'ordenes'...")
ordenes_data = [
    {
        'emisorNombre': 'Juan Pérez',
        'receptorNombre': 'María González',
        'descripcion': 'Paquete de documentos importantes',
        'direccionDestino': 'Calle Principal #123, Ciudad',
        'estado': 'EN TRANSITO',
        'fechaCreacion': firestore.SERVER_TIMESTAMP,
        'fechaEntrega': None,
        'observaciones': '',
        'createdBy': 'Super-Admin'
    },
    {
        'emisorNombre': 'Carlos Ruiz',
        'receptorNombre': 'Ana Martínez',
        'descripcion': 'Caja con productos electrónicos',
        'direccionDestino': 'Avenida Central #456, Ciudad',
        'estado': 'POR ENVIAR',
        'fechaCreacion': firestore.SERVER_TIMESTAMP,
        'fechaEntrega': None,
        'observaciones': 'Llamar antes de llegar',
        'createdBy': 'Super-Admin'
    },
    {
        'emisorNombre': 'Pedro López',
        'receptorNombre': 'Laura García',
        'descripcion': 'Paquete de ropa',
        'direccionDestino': 'Calle Norte #789, Ciudad',
        'estado': 'ENTREGADO',
        'fechaCreacion': firestore.SERVER_TIMESTAMP,
        'fechaEntrega': firestore.SERVER_TIMESTAMP,
        'observaciones': 'Entregado conforme',
        'createdBy': 'Super-Admin'
    },
    {
        'emisorNombre': 'Juan Pérez',
        'receptorNombre': 'Ana Martínez',
        'descripcion': 'Libros y material educativo',
        'direccionDestino': 'Plaza Mayor #321, Ciudad',
        'estado': 'EN TRANSITO',
        'fechaCreacion': firestore.SERVER_TIMESTAMP,
        'fechaEntrega': None,
        'observaciones': '',
        'createdBy': 'Super-Admin'
    },
    {
        'emisorNombre': 'Carlos Ruiz',
        'receptorNombre': 'Laura García',
        'descripcion': 'Productos de farmacia',
        'direccionDestino': 'Avenida Sur #654, Ciudad',
        'estado': 'POR ENVIAR',
        'fechaCreacion': firestore.SERVER_TIMESTAMP,
        'fechaEntrega': None,
        'observaciones': 'Frágil, manejar con cuidado',
        'createdBy': 'Super-Admin'
    }
]

for orden in ordenes_data:
    db.collection('ordenes').add(orden)
    print(f"   ✓ Orden '{orden['descripcion'][:30]}...' creada")

print()
print("=" * 60)
print("🎉 ¡CONFIGURACIÓN COMPLETADA EXITOSAMENTE!")
print("=" * 60)
print()
print("✅ Colecciones creadas:")
print("   - emisores (3 documentos)")
print("   - receptores (3 documentos)")
print("   - ordenes (5 documentos)")
print()
print("🚀 Ahora puedes conectar tu app Flutter con Firebase!")
print()

