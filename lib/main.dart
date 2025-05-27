import 'package:app_fitness/controller/local_notes_controller.dart';
import 'package:app_fitness/core/service/fitness_ai_service.dart';
import 'package:app_fitness/data/repositories/local_notes_repository.dart';
import 'package:app_fitness/model/local_workout_notes.dart';
import 'package:app_fitness/presentation/pages/work_note_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:app_fitness/core/config/app_config.dart';
import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/data/repositories/user_profile_repository.dart';
import 'package:app_fitness/data/repositories/workout_repository.dart';
import 'package:app_fitness/data/repositories/recipe_repository.dart';
import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/controller/user_profile_controller.dart';
import 'package:app_fitness/controller/fitness_controller.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';
import 'package:app_fitness/presentation/pages/profile_page.dart';
import 'package:app_fitness/presentation/pages/register_page.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno (ej. API Key de Gemini)
  await dotenv.load(fileName: ".env");

  // Inicialización de Hive para almacenamiento local offline
  await Hive.initFlutter();
  Hive.registerAdapter(
    LocalWorkoutNoteAdapter(),
  ); // Registrar el adaptador generado para tu modelo de notas
  await Hive.openBox<LocalWorkoutNote>(
    'workout_notes_box',
  ); // Abrir el Box donde se guardarán las notas

  final account = AppConfig.account;
  final databases = AppConfig.databases;

  final authRepository = AuthRepository(account);
  Get.put(authRepository);
  final userProfileRepository = UserProfileRepository(databases);
  Get.put(userProfileRepository);
  final workoutRepository = WorkoutRepository(databases);
  Get.put(workoutRepository);
  final recipeRepository = RecipeRepository(databases);
  Get.put(recipeRepository);
  final localNotesRepository =
      LocalNotesRepository(); // Para notas offline con Hive
  Get.put(localNotesRepository);
  final fitnessAiService = FitnessAiService();
  Get.put(fitnessAiService);
  Get.put(AuthController(authRepository));
  Get.put(UserProfileController());
  Get.put(FitnessController());
  Get.put(LocalNotesController());
  final authController = Get.find<AuthController>();
  final isLoggedIn = await authController.checkAuthStatusForAppStart();

  runApp(
    GetMaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/home', page: () => HomePage()),
        GetPage(name: '/profile', page: () => ProfilePage()),
        GetPage(name: '/edit-workout-note', page: () => WorkoutNoteEditPage()),
      ],
    ),
  );
}
