import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class FitnessAiService {
  GenerativeModel? _model;
  bool _isInitialized = false;

  FitnessAiService() {
    _initialize();
  }

  Future<void> _initialize() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('GEMINI_API_KEY no encontrada en el archivo .env.');
      _isInitialized = false;
      return;
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.7),
    );
    _isInitialized = true;
    print("FitnessAiService inicializado correctamente.");
  }

  bool get isInitialized => _isInitialized;

  String _cleanGeminiResponse(String rawResponse, {bool expectObject = true}) {
    String cleaned = rawResponse.trim();

    if (cleaned.startsWith("```json\n")) {
      cleaned = cleaned.substring(7);
      if (cleaned.endsWith("\n```")) {
        cleaned = cleaned.substring(0, cleaned.length - 4);
      } else if (cleaned.endsWith("```")) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    } else if (cleaned.startsWith("```")) {
      cleaned = cleaned.substring(3);
      if (cleaned.endsWith("```")) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    }

    if (cleaned.toLowerCase().startsWith("json")) {
      int startIndex = cleaned.indexOf(expectObject ? '{' : '[');
      if (startIndex != -1) {
        cleaned = cleaned.substring(startIndex);
      }
    }
    return cleaned.trim();
  }

  Future<String> generateWorkoutRoutine({
    required String userName,
    int? userAge,
    double? userWeight,
    required String userGoal,
    required String userFitnessLevel,
    List<String>? preferredMuscleGroups,
    int daysPerWeek = 4,
  }) async {
    if (!_isInitialized || _model == null) {
      throw Exception(
        "FitnessAiService no está inicializado. Verifica la API Key de Gemini.",
      );
    }

    final prompt = """
    Eres un entrenador personal experto y motivador llamado "FitMentor AI".
    Genera una rutina de ejercicios altamente personalizada, detallada y motivadora para un usuario llamado $userName.

    Considera los siguientes datos del usuario:
    - Nombre: $userName
    - Edad: ${userAge ?? "No especificada"} años
    - Peso: ${userWeight ?? "No especificado"} kg
    - Objetivo Principal: $userGoal (ej. "ganar masa muscular", "perder grasa y tonificar", "mejorar resistencia")
    - Nivel de Fitness Actual: $userFitnessLevel (ej. "principiante con poca experiencia", "intermedio, entrena 3 veces/semana", "avanzado, más de 2 años entrenando")
    ${preferredMuscleGroups != null && preferredMuscleGroups.isNotEmpty ? "- Grupos musculares a priorizar: ${preferredMuscleGroups.join(', ')}" : ""}
    - Días disponibles para entrenar por semana: $daysPerWeek

    El plan debe incluir:
    1. Una breve introducción motivadora y personalizada para $userName, explicando el enfoque del plan.
    2. Un desglose por cada día de entrenamiento. El nombre de cada día debe ser descriptivo y puede incluir el nombre del usuario (ej. 'Día 1: Empuje y Potencia para $userName').

    Para cada ejercicio dentro de cada día, detalla:
    - 'name': Nombre completo del ejercicio (string).
    - 'sets': Número de series (integer).
    - 'reps': Rango de repeticiones o tiempo (string, ej. "8-12", "15", "30 segundos").
    - 'rest': Tiempo de descanso en segundos después de todas las series de ese ejercicio (integer, ej. 60, 90).
    - 'notes': Consejos clave de técnica, forma, o alternativas si es un ejercicio complejo (string, opcional).

    Estructura de la respuesta:
    Devuelve la respuesta EXCLUSIVAMENTE en formato JSON. El JSON debe tener una clave principal "workoutPlan" que sea un objeto.
    Este objeto "workoutPlan" debe contener:
    - una clave "introduction" (string, el mensaje introductorio para $userName).
    - una clave "days" que será un array de objetos, donde cada objeto representa un día de entrenamiento.
    Cada objeto de día (dentro del array "days") debe tener:
      - una clave "dayName" (string).
      - una clave "exercises" que sea un array de objetos de ejercicio (con las claves 'name', 'sets', 'reps', 'rest', 'notes').

    Asegúrate de que el JSON sea sintácticamente válido y completo según esta estructura.
    Adapta la intensidad y complejidad de los ejercicios al nivel de fitness y objetivo de $userName.
    """;

    try {
      print(
        "Enviando prompt de rutina personalizado a Gemini para $userName (Objetivo: $userGoal, Nivel: $userFitnessLevel)...",
      );
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception("Gemini no devolvió contenido para la rutina.");
      }
      print("Respuesta cruda de Gemini (rutina para $userName): $responseText");

      String cleanedResponseText = _cleanGeminiResponse(
        responseText,
        expectObject: true,
      );
      print(
        "Respuesta de Gemini (limpia para rutina de $userName): $cleanedResponseText",
      );

      try {
        jsonDecode(cleanedResponseText);
        return cleanedResponseText;
      } catch (e) {
        print(
          "La respuesta de Gemini para la rutina (después de limpiar) no es un JSON válido: $e",
        );
        throw Exception(
          "Formato de respuesta inválido para la rutina.\nOriginal: $responseText\nLimpiado: $cleanedResponseText",
        );
      }
    } catch (e) {
      print("Error al generar rutina con Gemini para $userName: $e");
      throw Exception(
        "Error al generar la rutina para $userName: ${e.toString()}",
      );
    }
  }

  Future<String> generateRecipes({
    required String userName,
    int? userAge,
    double? userWeight,
    required String userGoal,
    String? userFitnessLevel,
    int numberOfRecipes = 3,
    List<String>? dietaryRestrictions,
    List<String>? preferredIngredients,
    List<String>? dislikedIngredients,
  }) async {
    if (!_isInitialized || _model == null) {
      throw Exception(
        "FitnessAiService no está inicializado. Verifica la API Key de Gemini.",
      );
    }

    final prompt = """
    Eres un nutricionista experto y creativo llamado "NutriFit AI".
    Sugiere $numberOfRecipes recetas saludables, deliciosas y fáciles de preparar, específicamente diseñadas para un usuario llamado $userName.

    Considera el siguiente perfil y preferencias del usuario:
    - Nombre: $userName
    - Edad: ${userAge ?? "No especificada"} años
    - Peso: ${userWeight ?? "No especificado"} kg
    - Objetivo Principal de Fitness: $userGoal
    - Nivel de Fitness (puede influir en las necesidades calóricas y tipo de comidas): ${userFitnessLevel ?? "No especificado"}
    ${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? "- Restricciones Alimentarias Importantes: ${dietaryRestrictions.join(', ')}." : ""}
    ${preferredIngredients != null && preferredIngredients.isNotEmpty ? "- Ingredientes que le gustan o quiere incluir: ${preferredIngredients.join(', ')}." : ""}
    ${dislikedIngredients != null && dislikedIngredients.isNotEmpty ? "- Ingredientes que NO le gustan o quiere evitar: ${dislikedIngredients.join(', ')}." : ""}

    Para cada una de las $numberOfRecipes recetas, proporciona la siguiente información:
    - 'name': Nombre atractivo de la receta (string).
    - 'type': Tipo de comida (string, ej. "Desayuno Energético", "Almuerzo Ligero", "Cena Reparadora", "Snack Proteico").
    - 'description': Una breve descripción apetitosa y motivadora para $userName, explicando por qué es buena para su objetivo (string, opcional).
    - 'ingredients': Lista detallada de ingredientes con cantidades precisas (array de strings, ej. ["150g de pechuga de pollo", "1/2 taza (cocida) de quinoa", "1 puñado de espinacas frescas"]).
    - 'preparation': Instrucciones claras, paso a paso, y concisas para la preparación (string).
    - 'calories': Calorías aproximadas por porción (integer).
    - 'protein': Gramos de proteína aproximados por porción (integer).
    - 'carbs': Gramos de carbohidratos aproximados por porción (integer).
    - 'fats': Gramos de grasas aproximados por porción (integer).

    Estructura de la respuesta:
    Devuelve la respuesta EXCLUSIVAMENTE en formato JSON. El JSON debe ser un objeto con una clave principal "recipes" que sea un array de objetos de receta.
    Asegúrate de que el JSON sea sintácticamente válido y completo según esta estructura.
    Prioriza la variedad, el sabor, la facilidad de preparación, y el cumplimiento del objetivo y las preferencias de $userName.
    """;

    try {
      print(
        "Enviando prompt de recetas personalizado a Gemini para $userName (Objetivo: $userGoal)...",
      );
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception("Gemini no devolvió contenido para las recetas.");
      }
      print(
        "Respuesta cruda de Gemini (recetas para $userName): $responseText",
      );

      String cleanedResponseText = _cleanGeminiResponse(
        responseText,
        expectObject: true,
      );
      print(
        "Respuesta de Gemini (limpia para recetas de $userName): $cleanedResponseText",
      );

      try {
        jsonDecode(cleanedResponseText);
        return cleanedResponseText;
      } catch (e) {
        print(
          "La respuesta de Gemini para las recetas (después de limpiar) no es un JSON válido: $e",
        );
        throw Exception(
          "Formato de respuesta inválido para las recetas.\nOriginal: $responseText\nLimpiado: $cleanedResponseText",
        );
      }
    } catch (e) {
      print("Error al generar recetas con Gemini para $userName: $e");
      throw Exception(
        "Error al generar las recetas para $userName: ${e.toString()}",
      );
    }
  }
}
