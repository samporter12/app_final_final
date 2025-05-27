import 'package:app_fitness/model/recipe_model.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as AppwriteModels;
import 'package:app_fitness/core/constants/appwrite_constants.dart';

class RecipeRepository {
  final Databases _databases;
  final String _collectionId = AppwriteConstants.recipesCollection;

  RecipeRepository(this._databases);

  Future<List<AppwriteModels.Document>> saveUserRecipes(
    List<RecipeModel> recipes,
    String userId,
  ) async {
    List<AppwriteModels.Document> savedDocuments = [];
    try {
      for (var recipe in recipes) {
        Map<String, dynamic> dataToSave = recipe.toJson();
        dataToSave['userId'] = userId;
        dataToSave['generatedAt'] = DateTime.now().toIso8601String();

        final doc = await _databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: _collectionId,
          documentId: ID.unique(),
          data: dataToSave,
          permissions: [
            Permission.read(Role.user(userId)),
            Permission.update(Role.user(userId)),
            Permission.delete(Role.user(userId)),
          ],
        );
        savedDocuments.add(doc);
      }
      return savedDocuments;
    } on AppwriteException catch (e) {
      print("AppwriteException en saveUserRecipes: ${e.message}");
      throw Exception("Error al guardar las recetas: ${e.message}");
    } catch (e) {
      print("Error general en saveUserRecipes: $e");
      throw Exception("Error inesperado al guardar las recetas.");
    }
  }

  Future<List<RecipeModel>> getRecipesForUser(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('generatedAt'),
        ],
      );

      if (response.documents.isNotEmpty) {
        return response.documents.map((doc) {
          Map<String, dynamic> data = doc.data;
          data['\$id'] = doc.$id;
          return RecipeModel.fromJson(data);
        }).toList();
      }
      return [];
    } on AppwriteException catch (e) {
      print("AppwriteException en getRecipesForUser: ${e.message}");
      if (e.code != 404) {
        throw Exception("Error al obtener las recetas: ${e.message}");
      }
      return [];
    } catch (e) {
      print("Error general en getRecipesForUser: $e");
      throw Exception("Error inesperado al obtener las recetas.");
    }
  }
}
