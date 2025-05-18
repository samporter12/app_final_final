import 'package:app_fitness/core/service/fitness_ai_service.dart';
import 'package:flutter/material.dart'; // Para .env
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'package:app_fitness/core/config/app_config.dart';
import 'package:app_fitness/core/constants/appwrite_constants.dart'; // Para IDs de colección

import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/data/repositories/user_profile_repository.dart';
import 'package:app_fitness/data/repositories/workout_repository.dart'; // Nuevo
import 'package:app_fitness/data/repositories/recipe_repository.dart'; // Nuevo

import 'package:app_fitness/controller/auth_controller.dart'; // Ajustado a tu estructura
import 'package:app_fitness/controller/user_profile_controller.dart'; // Ajustado
import 'package:app_fitness/controller/fitness_controller.dart'; // Nuevo

import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';
import 'package:app_fitness/presentation/pages/profile_page.dart';
import 'package:app_fitness/presentation/pages/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cargar variables de entorno (API Key de Gemini)
  await dotenv.load(
    fileName: ".env",
  ); // Asegúrate de tener este archivo en la raíz

  // --- Inicialización de Clientes Appwrite ---
  final account = AppConfig.account;
  final databases = AppConfig.databases;

  // --- Registro de Repositorios ---
  final authRepository = AuthRepository(account);
  Get.put(authRepository);

  final userProfileRepository = UserProfileRepository(databases);
  Get.put(userProfileRepository);

  final workoutRepository = WorkoutRepository(databases); // Nuevo
  Get.put(workoutRepository);

  final recipeRepository = RecipeRepository(databases); // Nuevo
  Get.put(recipeRepository);

  // --- Registro de Servicios ---
  final fitnessAiService = FitnessAiService(); // Nuevo
  Get.put(fitnessAiService);
  // Esperar a que el servicio de IA se inicialice si es necesario
  // Aunque el constructor de FitnessAiService llama a _initialize,
  // _initialize es async, por lo que la inicialización puede no haber terminado.
  // Si necesitas garantizar que esté inicializado antes de usarlo por primera vez,
  // puedes añadir un Future en FitnessAiService que se complete en _initialize
  // y hacer un `await fitnessAiService.initializationComplete;` aquí.
  // Por ahora, asumimos que estará listo cuando se necesite o manejará su estado interno.

  // --- Registro de Controladores ---
  // AuthController depende de AuthRepository
  Get.put(AuthController(authRepository));

  // UserProfileController depende de UserProfileRepository y AuthController
  Get.put(UserProfileController()); // Usa Get.find() internamente

  // FitnessController depende de varios (AI Service, UserProfileController, AuthController, y repositorios de fitness)
  Get.put(FitnessController()); // Nuevo, usa Get.find() internamente

  // --- Lógica de Arranque de la App ---
  final authController = Get.find<AuthController>();
  final isLoggedIn = await authController.checkAuthStatusForAppStart();

  runApp(
    GetMaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/home', page: () => HomePage()),
        GetPage(name: '/profile', page: () => ProfilePage()),
      ],
    ),
  );
}
