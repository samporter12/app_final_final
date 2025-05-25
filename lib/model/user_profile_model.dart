// lib/data/model/user_profile_model.dart

class UserProfileModel {
  String? id; // ID del documento de Appwrite ($id)
  final String userId; // ID del usuario de Appwrite Auth
  String name; // Nombre del usuario
  int? age; // Edad del usuario
  double? weight; // Peso del usuario en kg (puedes ajustar la unidad)
  String goal; // Objetivo: "muscle_gain", "deficit", "maintenance"
  String fitnessLevel; // Nivel: "beginner", "intermediate", "advanced"
  DateTime? createdAt;
  DateTime? updatedAt;

  UserProfileModel({
    this.id,
    required this.userId,
    required this.name,
    this.age,
    this.weight,
    required this.goal,
    required this.fitnessLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['\$id'] as String?,
      userId: json['userId'] as String,
      name: json['name'] as String? ?? '', // Asegurar que no sea null
      age: json['age'] as int?,
      weight:
          (json['weight'] as num?)
              ?.toDouble(), // Appwrite puede devolver int o double
      goal: json['goal'] as String,
      fitnessLevel: json['fitnessLevel'] as String,
      createdAt:
          json['\$createdAt'] != null
              ? DateTime.tryParse(json['\$createdAt'])
              : null,
      updatedAt:
          json['\$updatedAt'] != null
              ? DateTime.tryParse(json['\$updatedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'age': age,
      'weight': weight,
      'goal': goal,
      'fitnessLevel': fitnessLevel,
      // createdAt y updatedAt son manejados por Appwrite
    };
  }
}
