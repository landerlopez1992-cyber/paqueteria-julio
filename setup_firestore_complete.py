#!/usr/bin/env python3
"""
Script completo para configurar Firestore con:
- Usuarios (sin Firebase Auth - se creará desde Flutter)
- Emisores y Receptores
- Órdenes con estados completos
"""

import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta

# Inicializar Firebase Admin SDK
cred = credentials.Certificate('paqueteria-web-app-firebase-adminsdk-fbsvc-5846fb7c81.json')
firebase_admin.initialize_app(cred)

# Obtener referencia a Firestore
db = firestore.client()

print("=" * 70)
print("🔥 CONFIGURACIÓN COMPLETA DE FIREBASE - SISTEMA DE PAQUETERÍA")
print("=" * 70)
print()

# ==============================================================================
# 1. CREAR PERFILES DE USUARIOS EN FIRESTORE
# ==============================================================================
print("👥 Creando perfiles de usuarios en Firestore...")
print()

usuarios_data = [
    {
        'email': 'admin@paqueteria.com',
        'password': 'Admin123!',  # Solo para referencia, no se guarda en producción
        'nombre': 'Administrador Principal',
        'rol': 'ADMINISTRADOR',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'email': 'repartidor@paqueteria.com',
        'password': 'Rep123!',  # Solo para referencia
        'nombre': 'Juan Repartidor',
        'rol': 'REPARTIDOR',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    }
]

for usuario in usuarios_data:
    # Crear documento sin el campo password
    user_data = {k: v for k, v in usuario.items() if k != 'password'}
    db.collection('usuarios').document(usuario['email'].replace('@', '_at_').replace('.', '_')).set(user_data)
    print(f"   ✓ Perfil '{usuario['nombre']}' creado ({usuario['rol']})")
    print(f"      Email: {usuario['email']} | Password: {usuario['password']}")

print()

# ==============================================================================
# 2. LIMPIAR COLECCIONES EXISTENTES DE DATOS
# ==============================================================================
print("🗑️  Limpiando datos de prueba anteriores...")

def delete_collection(collection_name):
    docs = db.collection(collection_name).stream()
    deleted = 0
    for doc in docs:
        doc.reference.delete()
        deleted += 1
    if deleted > 0:
        print(f"   ✓ {deleted} documentos eliminados de '{collection_name}'")

delete_collection('emisores')
delete_collection('receptores')
delete_collection('ordenes')

print()

# ==============================================================================
# 3. CREAR EMISORES
# ==============================================================================
print("📦 Creando emisores...")
emisores_data = [
    {
        'nombre': 'Juan Pérez García',
        'telefono': '+56912345678',
        'direccion': 'Av. Libertador Bernardo O\'Higgins #1234, Santiago',
        'email': 'juan.perez@email.com',
        'rut': '12.345.678-9',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'María González López',
        'telefono': '+56987654321',
        'direccion': 'Calle Providencia #5678, Providencia',
        'email': 'maria.gonzalez@email.com',
        'rut': '98.765.432-1',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Comercial TechStore Ltda.',
        'telefono': '+56922334455',
        'direccion': 'Av. Apoquindo #4567, Las Condes',
        'email': 'ventas@techstore.cl',
        'rut': '76.123.456-7',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    }
]

for emisor in emisores_data:
    db.collection('emisores').add(emisor)
    print(f"   ✓ Emisor '{emisor['nombre']}' creado")

print()

# ==============================================================================
# 4. CREAR RECEPTORES
# ==============================================================================
print("📬 Creando receptores...")
receptores_data = [
    {
        'nombre': 'Carlos Ramírez Silva',
        'telefono': '+56911223344',
        'direccion': 'Paseo Bulnes #987, Santiago Centro',
        'email': 'carlos.ramirez@email.com',
        'rut': '23.456.789-0',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Ana Martínez Torres',
        'telefono': '+56966778899',
        'direccion': 'Av. Vicuña Mackenna #3210, Ñuñoa',
        'email': 'ana.martinez@email.com',
        'rut': '34.567.890-1',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Restaurante El Buen Sabor',
        'telefono': '+56933445566',
        'direccion': 'Av. Italia #1234, Providencia',
        'email': 'contacto@buensabor.cl',
        'rut': '77.234.567-8',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    },
    {
        'nombre': 'Laura Fernández Gómez',
        'telefono': '+56955667788',
        'direccion': 'Calle Bombero Ossa #567, Santiago',
        'email': 'laura.fernandez@email.com',
        'rut': '45.678.901-2',
        'activo': True,
        'createdAt': firestore.SERVER_TIMESTAMP
    }
]

for receptor in receptores_data:
    db.collection('receptores').add(receptor)
    print(f"   ✓ Receptor '{receptor['nombre']}' creado")

print()

# ==============================================================================
# 5. CREAR ÓRDENES CON TODOS LOS ESTADOS
# ==============================================================================
print("📋 Creando órdenes con diferentes estados...")

now = datetime.now()

ordenes_data = [
    {
        'numeroOrden': 'ORD-2025-001',
        'emisorNombre': 'Juan Pérez García',
        'emisorTelefono': '+56912345678',
        'emisorDireccion': 'Av. Libertador Bernardo O\'Higgins #1234, Santiago',
        'receptorNombre': 'Carlos Ramírez Silva',
        'receptorTelefono': '+56911223344',
        'receptorDireccion': 'Paseo Bulnes #987, Santiago Centro',
        'descripcion': 'Documentos legales importantes',
        'notasAdicionales': 'Entregar personalmente, requiere firma',
        'estado': 'CREADA',
        'estadoHistorial': [
            {'estado': 'CREADA', 'fecha': now.isoformat(), 'usuario': 'Administrador Principal'}
        ],
        'fechaCreacion': now.isoformat(),
        'fechaEstimadaEntrega': None,
        'fechaEntrega': None,
        'repartidorAsignado': None,
        'createdBy': 'admin@paqueteria.com',
        'activa': True
    },
    {
        'numeroOrden': 'ORD-2025-002',
        'emisorNombre': 'María González López',
        'emisorTelefono': '+56987654321',
        'emisorDireccion': 'Calle Providencia #5678, Providencia',
        'receptorNombre': 'Ana Martínez Torres',
        'receptorTelefono': '+56966778899',
        'receptorDireccion': 'Av. Vicuña Mackenna #3210, Ñuñoa',
        'descripcion': 'Paquete con ropa y accesorios',
        'notasAdicionales': 'Tocar el timbre, piso 4',
        'estado': 'ENVIADA',
        'estadoHistorial': [
            {'estado': 'CREADA', 'fecha': (now - timedelta(hours=2)).isoformat(), 'usuario': 'Administrador Principal'},
            {'estado': 'ENVIADA', 'fecha': (now - timedelta(hours=1)).isoformat(), 'usuario': 'Administrador Principal'}
        ],
        'fechaCreacion': (now - timedelta(hours=2)).isoformat(),
        'fechaEstimadaEntrega': (now + timedelta(days=1)).isoformat(),
        'fechaEntrega': None,
        'repartidorAsignado': 'Juan Repartidor',
        'createdBy': 'admin@paqueteria.com',
        'activa': True
    },
    {
        'numeroOrden': 'ORD-2025-003',
        'emisorNombre': 'Comercial TechStore Ltda.',
        'emisorTelefono': '+56922334455',
        'emisorDireccion': 'Av. Apoquindo #4567, Las Condes',
        'receptorNombre': 'Restaurante El Buen Sabor',
        'receptorTelefono': '+56933445566',
        'receptorDireccion': 'Av. Italia #1234, Providencia',
        'descripcion': 'Equipamiento tecnológico (2 notebooks, 1 impresora)',
        'notasAdicionales': 'Frágil - Manejar con cuidado',
        'estado': 'REPARTIENDO',
        'estadoHistorial': [
            {'estado': 'CREADA', 'fecha': (now - timedelta(days=1)).isoformat(), 'usuario': 'Administrador Principal'},
            {'estado': 'ENVIADA', 'fecha': (now - timedelta(hours=6)).isoformat(), 'usuario': 'Administrador Principal'},
            {'estado': 'REPARTIENDO', 'fecha': (now - timedelta(hours=1)).isoformat(), 'usuario': 'Juan Repartidor'}
        ],
        'fechaCreacion': (now - timedelta(days=1)).isoformat(),
        'fechaEstimadaEntrega': now.isoformat(),
        'fechaEntrega': None,
        'repartidorAsignado': 'Juan Repartidor',
        'createdBy': 'admin@paqueteria.com',
        'activa': True
    },
    {
        'numeroOrden': 'ORD-2025-004',
        'emisorNombre': 'Juan Pérez García',
        'emisorTelefono': '+56912345678',
        'emisorDireccion': 'Av. Libertador Bernardo O\'Higgins #1234, Santiago',
        'receptorNombre': 'Laura Fernández Gómez',
        'receptorTelefono': '+56955667788',
        'receptorDireccion': 'Calle Bombero Ossa #567, Santiago',
        'descripcion': 'Caja con libros de estudio',
        'notasAdicionales': 'Cliente conforme con la entrega',
        'estado': 'ENTREGADA',
        'estadoHistorial': [
            {'estado': 'CREADA', 'fecha': (now - timedelta(days=2)).isoformat(), 'usuario': 'Administrador Principal'},
            {'estado': 'ENVIADA', 'fecha': (now - timedelta(days=1, hours=18)).isoformat(), 'usuario': 'Administrador Principal'},
            {'estado': 'REPARTIENDO', 'fecha': (now - timedelta(days=1, hours=2)).isoformat(), 'usuario': 'Juan Repartidor'},
            {'estado': 'ENTREGADA', 'fecha': (now - timedelta(days=1)).isoformat(), 'usuario': 'Juan Repartidor'}
        ],
        'fechaCreacion': (now - timedelta(days=2)).isoformat(),
        'fechaEstimadaEntrega': (now - timedelta(days=1)).isoformat(),
        'fechaEntrega': (now - timedelta(days=1)).isoformat(),
        'repartidorAsignado': 'Juan Repartidor',
        'createdBy': 'admin@paqueteria.com',
        'activa': True
    },
    {
        'numeroOrden': 'ORD-2025-005',
        'emisorNombre': 'María González López',
        'emisorTelefono': '+56987654321',
        'emisorDireccion': 'Calle Providencia #5678, Providencia',
        'receptorNombre': 'Carlos Ramírez Silva',
        'receptorTelefono': '+56911223344',
        'receptorDireccion': 'Paseo Bulnes #987, Santiago Centro',
        'descripcion': 'Productos de farmacia',
        'notasAdicionales': 'Urgente - medicamentos recetados',
        'estado': 'CREADA',
        'estadoHistorial': [
            {'estado': 'CREADA', 'fecha': (now - timedelta(minutes=30)).isoformat(), 'usuario': 'Administrador Principal'}
        ],
        'fechaCreacion': (now - timedelta(minutes=30)).isoformat(),
        'fechaEstimadaEntrega': None,
        'fechaEntrega': None,
        'repartidorAsignado': None,
        'createdBy': 'admin@paqueteria.com',
        'activa': True
    }
]

for orden in ordenes_data:
    db.collection('ordenes').add(orden)
    print(f"   ✓ Orden '{orden['numeroOrden']}' - Estado: {orden['estado']}")

print()
print("=" * 70)
print("🎉 ¡CONFIGURACIÓN COMPLETADA EXITOSAMENTE!")
print("=" * 70)
print()
print("✅ Sistema configurado con:")
print(f"   👥 Usuarios:")
print(f"      - Admin: admin@paqueteria.com (password: Admin123!)")
print(f"      - Repartidor: repartidor@paqueteria.com (password: Rep123!)")
print(f"   📦 Emisores: {len(emisores_data)} documentos")
print(f"   📬 Receptores: {len(receptores_data)} documentos")
print(f"   📋 Órdenes: {len(ordenes_data)} documentos")
print()
print("📊 Estados de órdenes:")
print(f"   - CREADA: 2 órdenes")
print(f"   - ENVIADA: 1 orden")
print(f"   - REPARTIENDO: 1 orden")
print(f"   - ENTREGADA: 1 orden")
print()
print("⚠️  IMPORTANTE: Activa Email/Password Authentication en Firebase Console:")
print("   1. Ve a Authentication → Sign-in method")
print("   2. Habilita 'Email/Password'")
print()
print("🚀 ¡Ahora puedes conectar tu app Flutter con Firebase!")
print()
