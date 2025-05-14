import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as AppwriteModels; // Para el tipo User

class AuthRepository {
  final Account _account;

  AuthRepository(this._account); // Constructor que recibe Account

  Future<AppwriteModels.User> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return user;
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Error desconocido al registrar');
    } catch (e) {
      // Considera registrar este error con un servicio de logging más robusto
      print('Error inesperado en createAccount: $e');
      throw Exception(
        'Error inesperado al registrar. Por favor, inténtalo de nuevo.',
      );
    }
  }

  Future<AppwriteModels.Session> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } on AppwriteException catch (e) {
      // Personaliza mensajes de error comunes
      if (e.code == 401) {
        // Código común para credenciales inválidas
        throw Exception('Email o contraseña incorrectos.');
      } else if (e.code == 400 &&
          e.message != null &&
          e.message!.toLowerCase().contains("invalid email")) {
        throw Exception('El formato del email no es válido.');
      }
      throw Exception(
        e.message ?? 'Error al iniciar sesión. Verifica tu conexión.',
      );
    } catch (e) {
      print('Error inesperado en login: $e');
      throw Exception(
        'Error inesperado al iniciar sesión. Por favor, inténtalo de nuevo.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Error al cerrar sesión');
    } catch (e) {
      print('Error inesperado en logout: $e');
      throw Exception('Error inesperado al cerrar sesión.');
    }
  }

  /// Obtiene el usuario actualmente autenticado.
  /// Devuelve el objeto User si hay una sesión activa, o null si no la hay o si ocurre un error.
  Future<AppwriteModels.User?> getCurrentUser() async {
    try {
      // _account.get() devuelve el usuario actual si la sesión es válida.
      // Lanza una AppwriteException si no hay sesión o si la sesión es inválida.
      return await _account.get();
    } on AppwriteException catch (e) {
      // Es normal que esto falle si no hay usuario logueado (ej. la primera vez que abre la app)
      // No necesariamente es un "error" que mostrar al usuario, a menos que esperemos que esté logueado.
      print(
        "AppwriteException en getCurrentUser (puede ser normal si no hay sesión): ${e.message}",
      );
      return null;
    } catch (e) {
      print('Error inesperado en getCurrentUser: $e');
      // En caso de un error completamente inesperado, también devolvemos null.
      return null;
    }
  }

  /// Verifica si hay una sesión de usuario activa.
  Future<bool> isLoggedIn() async {
    try {
      await _account.get(); // Intenta obtener el usuario
      return true; // Si no hay excepción, el usuario está logueado
    } catch (_) {
      // Cualquier excepción (AppwriteException por no sesión, u otra) significa que no está logueado.
      return false;
    }
  }
}
