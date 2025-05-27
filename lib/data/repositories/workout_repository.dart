import 'dart:convert';
import 'package:app_fitness/model/exercise_model.dart';
import 'package:app_fitness/model/workout_routine_model.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as AppwriteModels;
import 'package:app_fitness/core/constants/appwrite_constants.dart';

class WorkoutRepository {
  final Databases _databases;

  final String _collectionId = AppwriteConstants.workoutsCollection;

  WorkoutRepository(this._databases);

  Future<AppwriteModels.Document> saveWorkoutRoutine(
    WorkoutRoutineModel routine,
    String userId,
  ) async {
    try {
      List<Map<String, dynamic>> daysAsJsonList =
          routine.days.map((day) => day.toJson()).toList();
      String daysJsonString = jsonEncode(daysAsJsonList);

      Map<String, dynamic> dataToSave = {
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'days': daysJsonString,
      };

      return await _databases.createDocument(
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
    } on AppwriteException catch (e) {
      print(
        "AppwriteException en saveWorkoutRoutine: ${e.message} (Code: ${e.code}, Response: ${e.response})",
      );
      throw Exception("Error al guardar la rutina: ${e.message}");
    } catch (e) {
      print("Error general en saveWorkoutRoutine: $e");
      throw Exception("Error inesperado al guardar la rutina.");
    }
  }

  Future<WorkoutRoutineModel?> getWorkoutRoutineForUser(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: _collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        final AppwriteModels.Document doc = response.documents.first;
        final Map<String, dynamic> dataFromDb = doc.data;

        String? daysJsonString = dataFromDb['days'] as String?;

        List<WorkoutDayModel> parsedDays = [];
        if (daysJsonString != null && daysJsonString.isNotEmpty) {
          List<dynamic> decodedDaysList = jsonDecode(daysJsonString);

          parsedDays =
              decodedDaysList
                  .map(
                    (dayJson) => WorkoutDayModel.fromJson(
                      dayJson as Map<String, dynamic>,
                    ),
                  )
                  .toList();
        } else {
          print(
            "Atributo 'days' está vacío o no es un string para el documento ${doc.$id}",
          );
        }

        return WorkoutRoutineModel(
          id: doc.$id,
          userId: dataFromDb['userId'] as String?,
          createdAt:
              dataFromDb['createdAt'] != null
                  ? DateTime.tryParse(dataFromDb['createdAt'])
                  : null,
          days: parsedDays,
        );
      }
      return null;
    } on AppwriteException catch (e) {
      print(
        "AppwriteException en getWorkoutRoutineForUser: ${e.message} (Code: ${e.code})",
      );
      if (e.code == 404) {
        return null;
      }
      throw Exception("Error al obtener la rutina: ${e.message}");
    } catch (e) {
      print("Error general en getWorkoutRoutineForUser: $e");
      throw Exception("Error inesperado al obtener la rutina.");
    }
  }
}
