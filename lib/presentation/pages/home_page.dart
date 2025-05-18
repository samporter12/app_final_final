// lib/presentation/pages/home_page.dart
import 'package:app_fitness/model/recipe_model.dart';
import 'package:app_fitness/model/workout_routine_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_fitness/controller/auth_controller.dart'; // Ajustado
import 'package:app_fitness/controller/user_profile_controller.dart'; // Ajustado
import 'package:app_fitness/controller/fitness_controller.dart'; // Nuevo

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = Get.find();
  final UserProfileController _userProfileController = Get.find();
  final FitnessController _fitnessController = Get.find(); // Nuevo

  @override
  void initState() {
    super.initState();
    // Cargar perfil si no está cargado y luego generar plan
    // Esto asegura que tenemos el perfil antes de pedir el plan
    _loadProfileAndFitnessPlan();
  }

  Future<void> _loadProfileAndFitnessPlan() async {
    // Asegurarse de que el perfil del usuario esté cargado
    if (_userProfileController.userProfile.value == null) {
      await _userProfileController.loadUserProfile();
    }
    // Si después de cargar, el perfil sigue siendo null, no hacer nada más.
    if (_userProfileController.userProfile.value == null) {
      // Podrías mostrar un mensaje o redirigir si el perfil es esencial aquí
      print("HomePage: Perfil no disponible para generar plan.");
      if (mounted) {
        Get.snackbar(
          "Error de Perfil",
          "No se pudo cargar tu perfil. Intenta de nuevo o ve a la página de perfil.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    // Una vez que el perfil está disponible, generar el plan de fitness
    // El método generateFullFitnessPlan ya maneja la carga desde el repo o la generación.
    // El parámetro forceRegenerate puede ser false por defecto.
    // Si quieres un botón para "regenerar", ese botón pasaría true.
    if (mounted) {
      // Verificar si el widget sigue montado
      await _fitnessController.generateFullFitnessPlan(forceRegenerate: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final userName = _authController.currentUser.value?.name;
          return Text(
            userName != null && userName.isNotEmpty
                ? 'Hola, $userName'
                : 'Mi Plan Fitness',
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Get.toNamed('/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Regenerar plan",
            onPressed: () {
              // Mostrar diálogo de confirmación antes de regenerar
              Get.defaultDialog(
                title: "Regenerar Plan",
                middleText:
                    "¿Estás seguro de que quieres generar un nuevo plan de ejercicios y recetas? El plan actual (si existe en el servidor) no se borrará, pero se generará uno nuevo.",
                textConfirm: "Sí, Regenerar",
                textCancel: "Cancelar",
                onConfirm: () {
                  Get.back(); // Cerrar diálogo
                  _fitnessController.generateFullFitnessPlan(
                    forceRegenerate: true,
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authController.logout();
              _fitnessController
                  .clearFitnessDataOnLogout(); // Limpiar datos de fitness
            },
          ),
        ],
      ),
      body: Obx(() {
        // Usar Obx para reaccionar a los cambios en FitnessController
        // Mostrar errores globales del FitnessController
        if (_fitnessController.fitnessError.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error al cargar el plan:\n${_fitnessController.fitnessError.value}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Intentar de Nuevo"),
                    onPressed: () {
                      _fitnessController.generateFullFitnessPlan(
                        forceRegenerate: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        // Mostrar indicadores de carga
        bool isLoading =
            _fitnessController.isLoadingWorkout.value ||
            _fitnessController.isLoadingRecipes.value;
        if (isLoading &&
            _fitnessController.currentWorkoutRoutine.value == null &&
            _fitnessController.currentRecipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  "Generando tu plan personalizado...",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Si no hay datos y no hay error (podría ser el estado inicial antes de la primera generación)
        if (_fitnessController.currentWorkoutRoutine.value == null &&
            _fitnessController.currentRecipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Aún no tienes un plan de fitness.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Presiona el botón de actualizar en la barra superior para generar uno.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Generar mi Plan Ahora"),
                    onPressed: () {
                      _fitnessController.generateFullFitnessPlan(
                        forceRegenerate: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        // Mostrar el plan de fitness y recetas
        return DefaultTabController(
          length: 2, // Pestaña para Rutina y Pestaña para Recetas
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.fitness_center), text: "Rutina"),
                  Tab(icon: Icon(Icons.restaurant_menu), text: "Recetas"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildWorkoutTab(
                      _fitnessController.currentWorkoutRoutine.value,
                      _fitnessController.isLoadingWorkout.value,
                    ),
                    _buildRecipesTab(
                      _fitnessController.currentRecipes,
                      _fitnessController.isLoadingRecipes.value,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildWorkoutTab(WorkoutRoutineModel? routine, bool isLoading) {
    if (isLoading && routine == null) {
      // Cargando por primera vez la rutina
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Cargando rutina..."),
          ],
        ),
      );
    }
    if (routine == null || routine.days.isEmpty) {
      return const Center(
        child: Text(
          "No se encontró una rutina de ejercicios. Intenta regenerar.",
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: routine.days.length,
      itemBuilder: (context, index) {
        final day = routine.days[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            title: Text(
              day.dayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            children:
                day.exercises.map((exercise) {
                  return ListTile(
                    title: Text(
                      exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      "Series: ${exercise.sets}, Reps: ${exercise.reps}, Descanso: ${exercise.rest}s\n${exercise.notes != null && exercise.notes!.isNotEmpty ? 'Notas: ${exercise.notes}' : ''}",
                    ),
                    isThreeLine:
                        exercise.notes != null && exercise.notes!.isNotEmpty,
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRecipesTab(List<RecipeModel> recipes, bool isLoading) {
    if (isLoading && recipes.isEmpty) {
      // Cargando por primera vez las recetas
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Cargando recetas..."),
          ],
        ),
      );
    }
    if (recipes.isEmpty) {
      return const Center(
        child: Text("No se encontraron recetas. Intenta regenerar."),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            title: Text(
              recipe.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              recipe.type +
                  (recipe.calories != null ? " - ${recipe.calories} kcal" : ""),
            ),
            childrenPadding: const EdgeInsets.all(16.0),
            children: [
              if (recipe.description != null && recipe.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    recipe.description!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              Text(
                "Ingredientes:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...recipe.ingredients.map((ing) => Text("- $ing")).toList(),
              const SizedBox(height: 8),
              Text(
                "Preparación:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(recipe.preparation),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (recipe.protein != null)
                    Chip(label: Text("Prot: ${recipe.protein}g")),
                  if (recipe.carbs != null)
                    Chip(label: Text("Carbs: ${recipe.carbs}g")),
                  if (recipe.fats != null)
                    Chip(label: Text("Grasas: ${recipe.fats}g")),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
