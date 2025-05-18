import 'package:app_fitness/model/exercise_model.dart'; // Ajustado a tu estructura

class WorkoutRoutineModel {
  final List<WorkoutDayModel> days;
  String? id; // Para el ID del documento de Appwrite
  String? userId; // Para el userId asociado
  DateTime? createdAt; // Para la fecha de creación

  WorkoutRoutineModel({
    required this.days,
    this.id,
    this.userId,
    this.createdAt,
  });

  factory WorkoutRoutineModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('workoutPlan') && json['workoutPlan'] is Map) {
      var planData = json['workoutPlan'] as Map<String, dynamic>;
      if (planData.containsKey('days') && planData['days'] is List) {
        var daysList = planData['days'] as List;
        List<WorkoutDayModel> parsedDays =
            daysList
                .map((i) => WorkoutDayModel.fromJson(i as Map<String, dynamic>))
                .toList();
        return WorkoutRoutineModel(
          days: parsedDays,
          id: json['\$id'] as String?, // Si cargas desde Appwrite
          userId: json['userId'] as String?, // Si cargas desde Appwrite
          createdAt:
              json['\$createdAt'] !=
                      null // O el nombre de tu campo de fecha
                  ? DateTime.tryParse(json['\$createdAt'])
                  : null,
        );
      }
    }
    throw FormatException(
      "Formato JSON inesperado para WorkoutRoutineModel. Contenido: $json",
    );
  }

  Map<String, dynamic> toJson() {
    // Para guardar en Appwrite
    return {
      // 'userId': userId, // Se añade en el repositorio antes de guardar
      // 'createdAt': createdAt?.toIso8601String(), // Se añade en el repositorio
      'days': days.map((d) => d.toJson()).toList(),
      // La estructura de Gemini es "workoutPlan": {"days": [...] }
      // Así que al guardar, podrías querer anidar esto si tu colección de Appwrite lo espera así
      // o simplemente guardar el contenido de "days". Por simplicidad, guardamos "days".
      // Si quieres replicar la estructura de Gemini:
      // 'workoutPlan': {
      //   'days': days.map((d) => d.toJson()).toList(),
      // }
    };
  }
}
