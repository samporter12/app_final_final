import 'package:appwrite/appwrite.dart';

class AuthRepository {
  final Account account;

  AuthRepository(this.account);

  Future<void> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Error desconocido al registrar');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Credenciales incorrectas');
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'Error al cerrar sesión');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      await account.get();
      return true;
    } catch (_) {
      return false;
    }
  }
}
