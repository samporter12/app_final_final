// lib/data/repositories/workout_repository.dart
import 'dart:convert'; // Necesario para jsonEncode y jsonDecode
import 'package:app_fitness/model/exercise_model.dart';
import 'package:app_fitness/model/workout_routine_model.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as AppwriteModels;
import 'package:app_fitness/core/constants/appwrite_constants.dart';

class WorkoutRepository {
  final Databases _databases;
  // Asegúrate que este ID esté definido en AppwriteConstants y sea correcto,
  // y que la colección tenga los atributos definidos en appwrite_workout_attributes_config
  final String _collectionId = AppwriteConstants.workoutsCollection;

  WorkoutRepository(this._databases);

  Future<AppwriteModels.Document> saveWorkoutRoutine(
    WorkoutRoutineModel routine,
    String userId,
  ) async {
    try {
      // 1. Convertir la lista de WorkoutDayModel a una lista de Map<String, dynamic>
      List<Map<String, dynamic>> daysAsJsonList =
          routine.days.map((day) => day.toJson()).toList();

      // 2. Convertir esa lista de mapas a un string JSON
      String daysJsonString = jsonEncode(daysAsJsonList);

      // 3. Preparar los datos para Appwrite
      Map<String, dynamic> dataToSave = {
        // Asegúrate de que el atributo en Appwrite sea 'userId' (y no 'userld')
        'userId': userId,
        'createdAt': DateTime.now().toIso8601String(),
        'days': daysJsonString, // Guardar el string JSON en el atributo 'days'
        // Si tu WorkoutRoutineModel tiene otros campos a nivel raíz que quieres guardar,
        // y esos campos existen como atributos en Appwrite, añádelos aquí.
        // Por ejemplo, si tu routine.toJson() devolviera más cosas además de 'days':
        // ...routine.toJson(), // Esto podría sobrescribir 'days' si toJson() lo incluye.
        // Es mejor ser explícito:
        // 'routineName': routine.name, // si tuvieras un nombre para la rutina
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
          // Asegúrate de que el atributo en Appwrite sea 'userId' (y no 'userld')
          Query.equal('userId', userId),
          Query.orderDesc(
            'createdAt',
          ), // Asume que tienes un atributo 'createdAt'
          Query.limit(1),
        ],
      );

      if (response.documents.isNotEmpty) {
        final AppwriteModels.Document doc = response.documents.first;
        final Map<String, dynamic> dataFromDb = doc.data;

        // 1. Obtener el string JSON del atributo 'days'
        String? daysJsonString = dataFromDb['days'] as String?;

        List<WorkoutDayModel> parsedDays = [];
        if (daysJsonString != null && daysJsonString.isNotEmpty) {
          // 2. Decodificar el string JSON a una List<dynamic> (que será List<Map<String, dynamic>>)
          List<dynamic> decodedDaysList = jsonDecode(daysJsonString);

          // 3. Convertir la List<dynamic> a List<WorkoutDayModel>
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
          // Puedes decidir si devolver null o una rutina con días vacíos si 'days' no está.
          // Por ahora, si 'days' está vacío, la rutina tendrá una lista de días vacía.
        }

        // 4. Construir el WorkoutRoutineModel
        return WorkoutRoutineModel(
          id: doc.$id, // ID del documento de Appwrite
          userId: dataFromDb['userId'] as String?,
          createdAt:
              dataFromDb['createdAt'] != null
                  ? DateTime.tryParse(dataFromDb['createdAt'])
                  : null,
          days: parsedDays,
          // Si tienes otros campos a nivel raíz en tu documento de Appwrite
          // que pertenecen a WorkoutRoutineModel, cárgalos aquí.
          // routineName: dataFromDb['routineName'] as String?,
        );
      }
      return null; // No se encontró rutina
    } on AppwriteException catch (e) {
      print(
        "AppwriteException en getWorkoutRoutineForUser: ${e.message} (Code: ${e.code})",
      );
      if (e.code == 404) {
        return null; // Específicamente si no se encuentra, no es un error fatal.
      }
      throw Exception("Error al obtener la rutina: ${e.message}");
    } catch (e) {
      print("Error general en getWorkoutRoutineForUser: $e");
      throw Exception("Error inesperado al obtener la rutina.");
    }
  }
}
