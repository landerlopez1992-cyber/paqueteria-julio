import firebase_admin
from firebase_admin import credentials, firestore, auth
import os

SERVICE_ACCOUNT_KEY_PATH = 'paqueteria-web-app-firebase-adminsdk-fbsvc-5846fb7c81.json'

try:
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("🔥 Conectando a Firebase...")
    print("✅ Conexión exitosa!")
except Exception as e:
    print(f"❌ Error al inicializar Firebase: {e}")
    print("Asegúrate de que el archivo de clave privada esté en la raíz del proyecto y sea correcto.")
    exit()

def create_user_profile():
    print("======================================================================")
    print("👤 CREANDO PERFIL DE USUARIO EN FIRESTORE")
    print("======================================================================")

    try:
        # Obtener el usuario de Firebase Auth
        user = auth.get_user_by_email('admin@paqueteria.com')
        print(f"✅ Usuario encontrado: {user.email} (UID: {user.uid})")
        
        # Crear perfil en Firestore
        user_profile = {
            'email': 'admin@paqueteria.com',
            'nombre': 'Administrador Principal',
            'rol': 'ADMINISTRADOR',
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }
        
        # Guardar en Firestore
        db.collection('usuarios').document(user.uid).set(user_profile)
        print(f"✅ Perfil creado en Firestore para {user.email}")
        print(f"   👤 Nombre: {user_profile['nombre']}")
        print(f"   🔑 Rol: {user_profile['rol']}")
        print(f"   🆔 UID: {user.uid}")
        
    except Exception as e:
        print(f"❌ Error creando perfil: {e}")

if __name__ == "__main__":
    create_user_profile()
    print("\n======================================================================")
    print("✅ PROCESO COMPLETADO")
    print("======================================================================")
    print("\n🔐 Ahora puedes hacer login con:")
    print("  Email: admin@paqueteria.com")
    print("  Password: Admin123!")
    print("  Rol: ADMINISTRADOR")
