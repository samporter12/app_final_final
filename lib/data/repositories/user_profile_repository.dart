import 'package:app_fitness/model/user_profile_model.dart';
import 'package:appwrite/appwrite.dart';
import 'package:app_fitness/core/constants/appwrite_constants.dart';
import 'package:appwrite/models.dart' as Models;

class UserProfileRepository {
  final Databases _databases;

  UserProfileRepository(this._databases);

  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final Models.DocumentList result = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profileCollection,
        queries: [
          Query.equal('userId', userId),
          Query.limit(1), // Esperamos solo un perfil por usuario
        ],
      );
      if (result.documents.isNotEmpty) {
        return UserProfileModel.fromJson(result.documents.first.data);
      }
      return null; // No se encontró perfil
    } on AppwriteException catch (e) {
      print('AppwriteException en getUserProfile: ${e.message}');
      throw Exception('Error al obtener el perfil: ${e.message}');
    } catch (e) {
      print('Error general en getUserProfile: $e');
      throw Exception('Error inesperado al obtener el perfil.');
    }
  }

  Future<Models.Document> saveUserProfile(UserProfileModel profile) async {
    try {
      return await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profileCollection,
        documentId:
            ID.unique(), // Appwrite generará un ID único para el documento
        data: profile.toJson(),
        permissions: [
          Permission.read(
            Role.user(profile.userId),
          ), // Solo el usuario puede leer
          Permission.update(
            Role.user(profile.userId),
          ), // Solo el usuario puede actualizar
          Permission.delete(
            Role.user(profile.userId),
          ), // Solo el usuario puede borrar
        ],
      );
    } on AppwriteException catch (e) {
      print('AppwriteException en saveUserProfile: ${e.message}');
      throw Exception('Error al guardar el perfil: ${e.message}');
    } catch (e) {
      print('Error general en saveUserProfile: $e');
      throw Exception('Error inesperado al guardar el perfil.');
    }
  }

  Future<Models.Document> updateUserProfile(UserProfileModel profile) async {
    if (profile.id == null) {
      // profile.id es el $id del DOCUMENTO del perfil
      throw Exception(
        "ID del documento del perfil es necesario para actualizar.",
      );
    }
    try {
      return await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.profileCollection,
        documentId: profile.id!, // ID del DOCUMENTO del perfil
        data: profile.toJson(),
        // Los permisos ya deberían estar establecidos, pero se pueden reafirmar si es necesario
      );
    } on AppwriteException catch (e) {
      print('AppwriteException en updateUserProfile: ${e.message}');
      throw Exception('Error al actualizar el perfil: ${e.message}');
    } catch (e) {
      print('Error general en updateUserProfile: $e');
      throw Exception('Error inesperado al actualizar el perfil.');
    }
  }
}
