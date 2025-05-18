// lib/data/model/exercise_model.dart

class ExerciseModel {
  final String name;
  final int sets;
  final String
  reps; // Puede ser un rango como "8-12" o un número como "15" o "Al fallo"
  final int rest; // en segundos
  final String? notes; // Opcional

  ExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    this.notes,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      name: json['name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as String,
      rest: json['rest'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'rest': rest,
      'notes': notes,
    };
  }
}

class WorkoutDayModel {
  final String dayName;
  final List<ExerciseModel> exercises;

  WorkoutDayModel({required this.dayName, required this.exercises});

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) {
    var exercisesList = json['exercises'] as List;
    List<ExerciseModel> parsedExercises =
        exercisesList.map((i) => ExerciseModel.fromJson(i)).toList();

    return WorkoutDayModel(
      dayName: json['dayName'] as String,
      exercises: parsedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}
