import 'package:app_fitness/core/service/fitness_ai_service.dart';
import 'package:app_fitness/model/recipe_model.dart';
import 'package:app_fitness/model/user_profile_model.dart';
import 'package:app_fitness/model/workout_routine_model.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:app_fitness/data/repositories/workout_repository.dart';
import 'package:app_fitness/data/repositories/recipe_repository.dart';
import 'package:app_fitness/controller/user_profile_controller.dart';
import 'package:app_fitness/controller/auth_controller.dart';
import 'package:flutter/material.dart';

class FitnessController extends GetxController {
  final FitnessAiService _aiService = Get.find<FitnessAiService>();
  final UserProfileController _userProfileController =
      Get.find<UserProfileController>();
  final AuthController _authController = Get.find<AuthController>();

  final WorkoutRepository? _workoutRepository =
      Get.isRegistered<WorkoutRepository>()
          ? Get.find<WorkoutRepository>()
          : null;
  final RecipeRepository? _recipeRepository =
      Get.isRegistered<RecipeRepository>()
          ? Get.find<RecipeRepository>()
          : null;

  final RxBool isLoadingWorkout = false.obs;
  final RxBool isLoadingRecipes = false.obs;
  final Rx<WorkoutRoutineModel?> currentWorkoutRoutine =
      Rx<WorkoutRoutineModel?>(null);
  final RxList<RecipeModel> currentRecipes = <RecipeModel>[].obs;
  final RxString fitnessError = ''.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> generateFullFitnessPlan({bool forceRegenerate = false}) async {
    fitnessError.value = '';
    final UserProfileModel? profile = _userProfileController.userProfile.value;
    final String? userId = _authController.getCurrentUserId();

    if (!_aiService.isInitialized) {
      fitnessError.value =
          "Servicio de IA no inicializado. Verifica la API Key de Gemini.";
      Get.snackbar(
        "Error de Configuración",
        fitnessError.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (profile == null ||
        userId == null ||
        profile.id == null ||
        profile.id!.isEmpty) {
      fitnessError.value =
          "Perfil de usuario no disponible o incompleto. Por favor, completa tu perfil.";
      Get.snackbar(
        "Perfil Requerido",
        fitnessError.value,
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () => Get.toNamed('/profile'),
          child: const Text(
            "Ir al Perfil",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (profile.name.isEmpty ||
        profile.goal.isEmpty ||
        profile.fitnessLevel.isEmpty) {
      fitnessError.value =
          "Faltan datos clave en tu perfil (nombre, objetivo o nivel). Por favor, actualiza tu perfil.";
      Get.snackbar(
        "Perfil Incompleto",
        fitnessError.value,
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () => Get.toNamed('/profile'),
          child: const Text(
            "Actualizar Perfil",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    bool routineLoadedFromRepo = false;
    if (!forceRegenerate && _workoutRepository != null) {
      isLoadingWorkout.value = true;
      try {
        currentWorkoutRoutine.value = await _workoutRepository
            .getWorkoutRoutineForUser(userId);
        if (currentWorkoutRoutine.value != null) {
          routineLoadedFromRepo = true;
          print("Rutina cargada desde el repositorio para $userId.");
        }
      } catch (e) {
        print("Error cargando rutina desde repo: $e");
      }
      isLoadingWorkout.value = false;
    }

    if (!routineLoadedFromRepo || forceRegenerate) {
      await _generateAndSaveWorkoutRoutine(profile, userId);
    }

    bool recipesLoadedFromRepo = false;
    if (!forceRegenerate && _recipeRepository != null) {
      isLoadingRecipes.value = true;
      try {
        final recipes = await _recipeRepository.getRecipesForUser(userId);
        if (recipes.isNotEmpty) {
          currentRecipes.assignAll(recipes);
          recipesLoadedFromRepo = true;
          print("Recetas cargadas desde el repositorio para $userId.");
        }
      } catch (e) {
        print("Error cargando recetas desde repo: $e");
      }
      isLoadingRecipes.value = false;
    }

    if (!recipesLoadedFromRepo || forceRegenerate) {
      await _generateAndSaveRecipes(profile, userId);
    }

    if (currentWorkoutRoutine.value == null &&
        currentRecipes.isEmpty &&
        fitnessError.value.isEmpty) {
      fitnessError.value =
          "No se pudo generar ni cargar un plan. Inténtalo de nuevo.";
      Get.snackbar(
        "Plan no Generado",
        fitnessError.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (fitnessError.value.isEmpty &&
        (currentWorkoutRoutine.value != null || currentRecipes.isNotEmpty)) {
      Get.snackbar(
        "Plan Listo",
        "Tu plan de fitness y recetas están listos.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else if (fitnessError.value.isNotEmpty) {
      Get.snackbar(
        "Error en Plan",
        fitnessError.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 7),
      );
    }
  }

  Future<void> _generateAndSaveWorkoutRoutine(
    UserProfileModel profile,
    String userId,
  ) async {
    isLoadingWorkout.value = true;
    String? previousError =
        fitnessError.value.contains("rutina")
            ? null
            : (fitnessError.value.isEmpty ? null : fitnessError.value);

    try {
      final String routineJsonString = await _aiService.generateWorkoutRoutine(
        userName: profile.name,
        userAge: profile.age,
        userWeight: profile.weight,
        userGoal: profile.goal,
        userFitnessLevel: profile.fitnessLevel,
      );
      final Map<String, dynamic> routineJson = jsonDecode(routineJsonString);
      final newRoutine = WorkoutRoutineModel.fromJson(routineJson);
      newRoutine.userId = userId;
      newRoutine.createdAt = DateTime.now();
      currentWorkoutRoutine.value = newRoutine;

      if (_workoutRepository != null) {
        await _workoutRepository!.saveWorkoutRoutine(
          currentWorkoutRoutine.value!,
          userId,
        );
        print("Rutina guardada en Appwrite para $userId.");
      }
      fitnessError.value = previousError ?? '';
    } catch (e) {
      print("Error en _generateAndSaveWorkoutRoutine: $e");
      final routineError =
          "Error al generar rutina: ${e.toString().replaceFirst("Exception: ", "")}";
      fitnessError.value =
          previousError != null && previousError.isNotEmpty
              ? "$previousError\n$routineError"
              : routineError;
      currentWorkoutRoutine.value = null;
    } finally {
      isLoadingWorkout.value = false;
    }
  }

  Future<void> _generateAndSaveRecipes(
    UserProfileModel profile,
    String userId,
  ) async {
    isLoadingRecipes.value = true;
    String? previousError =
        fitnessError.value.contains("recetas")
            ? null
            : (fitnessError.value.isEmpty ? null : fitnessError.value);

    try {
      final String recipesJsonString = await _aiService.generateRecipes(
        userName: profile.name,
        userAge: profile.age,
        userWeight: profile.weight,
        userGoal: profile.goal,
        userFitnessLevel: profile.fitnessLevel,
      );
      final Map<String, dynamic> recipesJson = jsonDecode(recipesJsonString);
      final recipeListModel = RecipeListModel.fromJson(recipesJson);

      final processedRecipes =
          recipeListModel.recipes.map((recipe) {
            recipe.userId = userId;
            recipe.generatedAt = DateTime.now();
            return recipe;
          }).toList();
      currentRecipes.assignAll(processedRecipes);

      if (_recipeRepository != null && currentRecipes.isNotEmpty) {
        await _recipeRepository.saveUserRecipes(
          currentRecipes.toList(),
          userId,
        );
        print("Recetas guardadas en Appwrite para $userId.");
      }
      fitnessError.value = previousError ?? '';
    } catch (e) {
      print("Error en _generateAndSaveRecipes: $e");
      final recipeError =
          "Error al generar recetas: ${e.toString().replaceFirst("Exception: ", "")}";
      fitnessError.value =
          previousError != null && previousError.isNotEmpty
              ? "$previousError\n$recipeError"
              : recipeError;
      currentRecipes.clear();
    } finally {
      isLoadingRecipes.value = false;
    }
  }

  void clearFitnessDataOnLogout() {
    currentWorkoutRoutine.value = null;
    currentRecipes.clear();
    fitnessError.value = '';
    isLoadingWorkout.value = false;
    isLoadingRecipes.value = false;
    print("Datos de FitnessController limpiados.");
  }
}
