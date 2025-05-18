// lib/core/services/fitness_ai_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Para cargar la API Key
import 'package:google_generative_ai/google_generative_ai.dart'; // Paquete de Gemini
import 'dart:convert'; // Para decodificar JSON (jsonDecode)

class FitnessAiService {
  GenerativeModel? _model; // El modelo de IA generativa de Gemini
  bool _isInitialized =
      false; // Bandera para saber si el servicio se inicializó correctamente

  // Constructor: Llama a _initialize() para configurar el servicio.
  FitnessAiService() {
    _initialize();
  }

  // Método privado para inicializar el modelo de Gemini.
  Future<void> _initialize() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('GEMINI_API_KEY no encontrada en el archivo .env.');
      _isInitialized = false;
      return;
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
    _isInitialized = true;
    print("FitnessAiService inicializado correctamente.");
  }

  // Getter para verificar si el servicio está listo para usarse.
  bool get isInitialized => _isInitialized;

  String _cleanGeminiResponse(String rawResponse, {bool expectObject = true}) {
    String cleaned = rawResponse.trim();

    // Eliminar ```json al principio y ``` al final si existen
    if (cleaned.startsWith("```json\n")) {
      cleaned = cleaned.substring(7); // Longitud de "```json\n"
      if (cleaned.endsWith("\n```")) {
        cleaned = cleaned.substring(
          0,
          cleaned.length - 4,
        ); // Longitud de "\n```"
      } else if (cleaned.endsWith("```")) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    } else if (cleaned.startsWith("```")) {
      // Caso sin newline después de ```json
      cleaned = cleaned.substring(3);
      if (cleaned.endsWith("```")) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    }

    // Eliminar "json " (o similar) al principio si existe, después de los ```
    // y buscar el primer '{' o '['
    if (cleaned.toLowerCase().startsWith("json")) {
      // Encuentra el primer '{' o '[' después de la palabra "json"
      int objectIndex = cleaned.indexOf('{');
      int arrayIndex = cleaned.indexOf('[');

      if (expectObject) {
        if (objectIndex != -1) {
          cleaned = cleaned.substring(objectIndex);
        } else if (arrayIndex != -1 &&
            !cleaned.toLowerCase().startsWith("json {")) {
          // A veces Gemini da un array cuando se espera un objeto, si el prompt no fue 100% estricto.
          // O si la palabra "json" está seguida por un array.
          // Esto es menos común si el prompt es claro.
          cleaned = cleaned.substring(arrayIndex);
        }
      } else {
        // expectArray
        if (arrayIndex != -1) {
          cleaned = cleaned.substring(arrayIndex);
        } else if (objectIndex != -1 &&
            !cleaned.toLowerCase().startsWith("json [")) {
          cleaned = cleaned.substring(objectIndex);
        }
      }
    }

    return cleaned.trim();
  }

  Future<String> generateWorkoutRoutine({
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
    Eres un entrenador personal experto. Genera una rutina de ejercicios detallada para un usuario con las siguientes características:
    - Objetivo: $userGoal
    - Nivel de Fitness: $userFitnessLevel
    ${preferredMuscleGroups != null && preferredMuscleGroups.isNotEmpty ? "- Grupos musculares preferidos: ${preferredMuscleGroups.join(', ')}" : ""}
    - Días de entrenamiento por semana: $daysPerWeek

    Para cada día de entrenamiento, especifica un nombre descriptivo (ej. 'Día 1: Pecho y Tríceps').
    Para cada ejercicio, incluye:
    - 'name': nombre del ejercicio (string)
    - 'sets': número de series (integer)
    - 'reps': rango de repeticiones (string, ej. "8-12" o "15")
    - 'rest': tiempo de descanso en segundos después de todas las series de ese ejercicio (integer, ej. 60)
    - 'notes': notas adicionales o consejos para el ejercicio (string, opcional, ej. "Mantén la espalda recta")

    Devuelve la respuesta EXCLUSIVAMENTE en formato JSON. El JSON debe tener una clave principal "workoutPlan" que sea un objeto.
    Este objeto contendrá una clave "days" que será un array de objetos, donde cada objeto representa un día de entrenamiento.
    Cada objeto de día debe tener una clave "dayName" (string) y una clave "exercises" que sea un array de objetos de ejercicio.
    Asegúrate de que el JSON sea válido.
    """;

    try {
      print("Enviando prompt de rutina a Gemini...");
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception("Gemini no devolvió contenido para la rutina.");
      }
      print("Respuesta cruda de Gemini (rutina): $responseText");

      String cleanedResponseText = _cleanGeminiResponse(
        responseText,
        expectObject: true,
      );
      print("Respuesta de Gemini (limpia para rutina): $cleanedResponseText");

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
      print("Error al generar rutina con Gemini: $e");
      throw Exception("Error al generar la rutina: ${e.toString()}");
    }
  }

  Future<String> generateRecipes({
    required String userGoal,
    int numberOfRecipes = 3,
    String? dietaryRestrictions,
    List<String>? preferredIngredients,
    List<String>? dislikedIngredients,
  }) async {
    if (!_isInitialized || _model == null) {
      throw Exception(
        "FitnessAiService no está inicializado. Verifica la API Key de Gemini.",
      );
    }

    final prompt = """
    Eres un nutricionista experto. Sugiere $numberOfRecipes recetas saludables (ej. desayuno, almuerzo, cena) para un usuario con el siguiente objetivo: $userGoal.
    ${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? "Considera estas restricciones alimentarias: $dietaryRestrictions." : ""}
    ${preferredIngredients != null && preferredIngredients.isNotEmpty ? "Incluye si es posible estos ingredientes preferidos: ${preferredIngredients.join(', ')}." : ""}
    ${dislikedIngredients != null && dislikedIngredients.isNotEmpty ? "Evita estos ingredientes no deseados: ${dislikedIngredients.join(', ')}." : ""}

    Para cada receta, incluye:
    - 'name': nombre de la receta (string)
    - 'type': tipo de comida (string, ej. "Desayuno", "Almuerzo", "Cena", "Snack")
    - 'description': una breve descripción de la receta (string, opcional)
    - 'ingredients': lista de ingredientes con cantidades (array de strings, ej. ["1 pechuga de pollo (150g)", "1/2 taza de quinoa cocida"])
    - 'preparation': instrucciones claras y concisas de preparación (string)
    - 'calories': calorías aproximadas por porción (integer)
    - 'protein': gramos de proteína aproximados por porción (integer)
    - 'carbs': gramos de carbohidratos aproximados por porción (integer)
    - 'fats': gramos de grasas aproximados por porción (integer)

    Devuelve la respuesta EXCLUSIVAMENTE en formato JSON. El JSON debe ser un objeto con una clave principal "recipes" que sea un array de objetos de receta.
    Asegúrate de que el JSON sea válido.
    """;

    try {
      print("Enviando prompt de recetas a Gemini...");
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception("Gemini no devolvió contenido para las recetas.");
      }
      print("Respuesta cruda de Gemini (recetas): $responseText");

      // Para recetas, esperamos un objeto que contiene un array: {"recipes": [...]}
      String cleanedResponseText = _cleanGeminiResponse(
        responseText,
        expectObject: true,
      );
      print("Respuesta de Gemini (limpia para recetas): $cleanedResponseText");

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
      print("Error al generar recetas con Gemini: $e");
      throw Exception("Error al generar las recetas: ${e.toString()}");
    }
  }
}
