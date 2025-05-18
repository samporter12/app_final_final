class RecipeModel {
  final String name;
  final String type;
  final String? description;
  final List<String> ingredients;
  final String preparation;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fats;
  String? id; // Para el ID del documento de Appwrite
  String? userId; // Si las recetas son por usuario
  DateTime? generatedAt; // Si guardas cuándo se generó

  RecipeModel({
    required this.name,
    required this.type,
    this.description,
    required this.ingredients,
    required this.preparation,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
    this.id,
    this.userId,
    this.generatedAt,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['\$id'] as String?, // Si cargas desde Appwrite
      userId: json['userId'] as String?, // Si cargas desde Appwrite
      generatedAt:
          json['generatedAt'] !=
                  null // O el nombre de tu campo de fecha
              ? DateTime.tryParse(json['generatedAt'])
              : null,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      ingredients: List<String>.from(json['ingredients'] as List),
      preparation: json['preparation'] as String,
      calories: json['calories'] as int?,
      protein: json['protein'] as int?,
      carbs: json['carbs'] as int?,
      fats: json['fats'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'userId': userId, // Se añade en el repositorio
      // 'generatedAt': generatedAt?.toIso8601String(), // Se añade en el repositorio
      'name': name,
      'type': type,
      'description': description,
      'ingredients': ingredients,
      'preparation': preparation,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}

// Clase contenedora si Gemini devuelve un objeto con una clave "recipes"
class RecipeListModel {
  final List<RecipeModel> recipes;

  RecipeListModel({required this.recipes});

  factory RecipeListModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('recipes') && json['recipes'] is List) {
      var recipesList = json['recipes'] as List;
      List<RecipeModel> parsedRecipes =
          recipesList
              .map((i) => RecipeModel.fromJson(i as Map<String, dynamic>))
              .toList();
      return RecipeListModel(recipes: parsedRecipes);
    }
    throw FormatException(
      "Formato JSON inesperado para RecipeListModel. Contenido: $json",
    );
  }
}
