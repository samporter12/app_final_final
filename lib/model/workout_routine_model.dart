import 'package:app_fitness/model/exercise_model.dart';

class WorkoutRoutineModel {
  final List<WorkoutDayModel> days;
  String? id;
  String? userId;
  DateTime? createdAt;

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
          id: json['\$id'] as String?,
          userId: json['userId'] as String?,
          createdAt:
              json['\$createdAt'] != null
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
    return {'days': days.map((d) => d.toJson()).toList()};
  }
}
