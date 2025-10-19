import firebase_admin
from firebase_admin import credentials, auth
import os

SERVICE_ACCOUNT_KEY_PATH = 'paqueteria-web-app-firebase-adminsdk-fbsvc-5846fb7c81.json'

try:
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    print("🔥 Conectando a Firebase Admin SDK...")
    print("✅ Conexión exitosa!")
except Exception as e:
    print(f"❌ Error al inicializar Firebase Admin SDK: {e}")
    print("Asegúrate de que el archivo de clave privada esté en la raíz del proyecto y sea correcto.")
    exit()

def create_specific_user():
    print("======================================================================")
    print("🔐 CREANDO USUARIO ESPECÍFICO EN FIREBASE AUTHENTICATION")
    print("======================================================================")

    user_data = {
        'email': 'admin@paqueteria.com',
        'password': 'Admin123!',
        'displayName': 'Administrador Principal',
        'rol': 'ADMINISTRADOR'
    }

    try:
        # Intentar crear el usuario
        user = auth.create_user(
            email=user_data['email'],
            password=user_data['password'],
            display_name=user_data['displayName']
        )
        print(f"\n✅ Usuario '{user_data['displayName']}' creado exitosamente")
        print(f"   📧 Email: {user.email}")
        print(f"   🔑 Password: {user_data['password']}")
        print(f"   👤 Rol: {user_data['rol']}")
        print(f"   🆔 UID: {user.uid}")
        
    except auth.EmailAlreadyExistsError:
        print(f"\nℹ️  Usuario '{user_data['email']}' ya existe")
        # Obtener información del usuario existente
        try:
            user = auth.get_user_by_email(user_data['email'])
            print(f"   📧 Email: {user.email}")
            print(f"   👤 Display Name: {user.display_name}")
            print(f"   🆔 UID: {user.uid}")
            print(f"   ✅ Estado: Activo")
        except Exception as e:
            print(f"   ❌ Error obteniendo información del usuario: {e}")
            
    except Exception as e:
        print(f"\n❌ Error creando usuario {user_data['email']}: {e}")

if __name__ == "__main__":
    create_specific_user()
    print("\n======================================================================")
    print("✅ PROCESO COMPLETADO")
    print("======================================================================")
    print("\n🔐 Credenciales para login:")
    print("ADMINISTRADOR:")
    print("  Email: admin@paqueteria.com")
    print("  Password: Admin123!")
