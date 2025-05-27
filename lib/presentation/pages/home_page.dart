import 'package:app_fitness/model/exercise_model.dart';
import 'package:app_fitness/model/recipe_model.dart';
import 'package:app_fitness/model/workout_routine_model.dart';
import 'package:app_fitness/presentation/widgets/loading_indicator.dart';
import 'package:app_fitness/presentation/widgets/recipe_card.dart';
import 'package:app_fitness/presentation/widgets/section_title.dart';
import 'package:app_fitness/presentation/widgets/workout_day_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/controller/user_profile_controller.dart';
import 'package:app_fitness/controller/fitness_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthController _authController = Get.find();
  final UserProfileController _userProfileController = Get.find();
  final FitnessController _fitnessController = Get.find();

  @override
  void initState() {
    super.initState();
    _loadProfileAndFitnessPlan();
  }

  Future<void> _loadProfileAndFitnessPlan() async {
    if (_authController.currentUser.value == null) {
      print(
        "HomePage: No hay usuario autenticado, no se cargará ni generará plan.",
      );
      return;
    }
    if (_userProfileController.userProfile.value == null ||
        _userProfileController.userProfile.value!.id == null ||
        _userProfileController.userProfile.value!.id!.isEmpty) {
      print("HomePage: Perfil no cargado o incompleto, intentando cargar...");
      await _userProfileController.loadUserProfile();
    }
    if (_userProfileController.userProfile.value == null ||
        _userProfileController.userProfile.value!.id == null ||
        _userProfileController.userProfile.value!.id!.isEmpty) {
      print(
        "HomePage: Perfil no disponible o incompleto después de intentar cargar. El usuario debe completar el perfil.",
      );
      if (mounted) {
        Get.snackbar(
          "Perfil Incompleto",
          "Por favor, completa tu perfil para obtener un plan personalizado.",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () => Get.toNamed('/profile'),
            child: const Text(
              "Ir al Perfil",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
      }
      return;
    }

    print(
      "HomePage: Perfil disponible y usuario autenticado. Procediendo a generar/cargar plan.",
    );
    if (mounted) {
      await _fitnessController.generateFullFitnessPlan(forceRegenerate: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final userName = _authController.currentUser.value?.name;
          return Text(
            userName != null && userName.isNotEmpty
                ? 'Hola, $userName'
                : 'Mi Plan Fitness',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          );
        }),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: "Mi Perfil",
            onPressed: () => Get.toNamed('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Regenerar Plan",
            onPressed: () {
              Get.defaultDialog(
                title: "Regenerar Plan",
                middleText:
                    "¿Estás seguro de que quieres generar un nuevo plan de ejercicios y recetas? Esto podría tomar unos momentos.",
                textConfirm: "Sí, Regenerar",
                confirmTextColor: Colors.white,
                buttonColor: theme.colorScheme.primary,
                textCancel: "Cancelar",
                onConfirm: () {
                  Get.back();
                  _fitnessController.generateFullFitnessPlan(
                    forceRegenerate: true,
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () {
              _authController.logout();
            },
          ),
        ],
      ),
      body: Obx(() {
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
                    // Podrías reemplazarlo con tu StyledButton
                    icon: const Icon(Icons.refresh),
                    label: const Text("Intentar de Nuevo"),
                    onPressed:
                        () => _fitnessController.generateFullFitnessPlan(
                          forceRegenerate: true,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        bool isLoadingOverall =
            _fitnessController.isLoadingWorkout.value ||
            _fitnessController.isLoadingRecipes.value;
        bool noDataAvailable =
            _fitnessController.currentWorkoutRoutine.value == null &&
            _fitnessController.currentRecipes.isEmpty;

        if (isLoadingOverall && noDataAvailable) {
          return const LoadingIndicator(
            message: "Generando tu plan personalizado...",
          );
        }

        if (noDataAvailable && !isLoadingOverall) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Aún no tienes un plan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Presiona el botón de refrescar para generar uno.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    // Podrías reemplazarlo con tu StyledButton
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Generar mi Plan Ahora"),
                    onPressed:
                        () => _fitnessController.generateFullFitnessPlan(
                          forceRegenerate: true,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: theme.colorScheme.surfaceVariant,
                child: TabBar(
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3.0,
                  tabs: const [
                    Tab(icon: Icon(Icons.fitness_center), text: "Mi Rutina"),
                    Tab(icon: Icon(Icons.restaurant_menu), text: "Mis Recetas"),
                  ],
                ),
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
      return const LoadingIndicator(message: "Cargando rutina...");
    }
    if (routine == null || routine.days.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No se encontró una rutina de ejercicios.\nIntenta regenerar tu plan usando el botón de refrescar.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        const SectionTitle(title: "Tu Plan Semanal"),
        ...routine.days.asMap().entries.map((entry) {
          int dayIndex = entry.key;
          WorkoutDayModel day = entry.value;
          return WorkoutDayPanel(workoutDay: day, dayIndex: dayIndex);
        }).toList(),
      ],
    );
  }

  Widget _buildRecipesTab(List<RecipeModel> recipes, bool isLoading) {
    if (isLoading && recipes.isEmpty) {
      return const LoadingIndicator(message: "Cargando recetas...");
    }
    if (recipes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No se encontraron recetas.\nIntenta regenerar tu plan usando el botón de refrescar.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        const SectionTitle(title: "Sugerencias de Comidas"),
        ...recipes.asMap().entries.map((entry) {
          int recipeIndex = entry.key;
          RecipeModel recipe = entry.value;
          return RecipeCard(recipe: recipe, recipeIndex: recipeIndex);
        }).toList(),
      ],
    );
  }
}
