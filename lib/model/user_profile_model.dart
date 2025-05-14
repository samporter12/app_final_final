class UserProfileModel {
  String?
  id; // Para almacenar el ID del documento de Appwrite ($id). Es nullable.
  final String userId; // El ID del usuario de Appwrite Auth. Debe ser final.
  String goal; // Ya no es final, para permitir actualizaciones.
  String fitnessLevel; // Ya no es final, para permitir actualizaciones.
  DateTime? createdAt; // Para almacenar $createdAt de Appwrite.
  DateTime? updatedAt; // Para almacenar $updatedAt de Appwrite.

  // Puedes agregar más campos del perfil si los tienes, por ejemplo:
  // double? weight;
  // int? height;

  UserProfileModel({
    this.id, // El ID del documento es opcional al crear un nuevo perfil localmente.
    required this.userId,
    required this.goal,
    required this.fitnessLevel,
    this.createdAt,
    this.updatedAt,
    // this.weight,
    // this.height,
  });

  /// Factory constructor para crear una instancia de UserProfileModel desde un mapa JSON
  /// (generalmente, los datos que vienen de Appwrite).
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['\$id'], // El ID del documento de Appwrite.
      userId: json['userId'],
      goal: json['goal'],
      fitnessLevel: json['fitnessLevel'],
      createdAt:
          json['\$createdAt'] != null
              ? DateTime.tryParse(json['\$createdAt'])
              : null,
      updatedAt:
          json['\$updatedAt'] != null
              ? DateTime.tryParse(json['\$updatedAt'])
              : null,
      // weight: json['weight']?.toDouble(), // Ejemplo si tuvieras peso
      // height: json['height']?.toInt(),   // Ejemplo si tuvieras altura
    );
  }

  /// Convierte la instancia de UserProfileModel a un mapa JSON.
  /// Este mapa es el que se envía a Appwrite al crear o actualizar un documento.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'userId': userId, // userId se envía siempre.
      'goal': goal,
      'fitnessLevel': fitnessLevel,
      // 'weight': weight, // Ejemplo
      // 'height': height, // Ejemplo
    };
    // No incluimos 'id', '$createdAt', o '$updatedAt' en toJson porque Appwrite los maneja.
    return data;
  }
}
