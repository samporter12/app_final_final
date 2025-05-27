import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as AppwriteModels;

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

  Future<AppwriteModels.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } on AppwriteException catch (e) {
      print(
        "AppwriteException en getCurrentUser (puede ser normal si no hay sesión): ${e.message}",
      );
      return null;
    } catch (e) {
      print('Error inesperado en getCurrentUser: $e');

      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      await _account.get();
      return true;
    } catch (_) {
      return false;
    }
  }
}
