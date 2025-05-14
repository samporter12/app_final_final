import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/controller/user_profile_controller.dart';
import 'package:app_fitness/core/config/app_config.dart';
import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';
import 'package:app_fitness/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_fitness/data/repositories/user_profile_repository.dart';
import 'package:app_fitness/presentation/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Dependencias de Autenticación ---
  // 1. Obtén la instancia de Account desde AppConfig
  final account = AppConfig.account;

  // 2. Crea y registra AuthRepository
  final authRepository = AuthRepository(account);
  Get.put(
    authRepository,
  ); // Registrar la instancia para que Get.find() funcione en otros lados

  // 3. Crea y registra AuthController, pasándole el AuthRepository
  Get.put(
    AuthController(authRepository),
  ); // AuthController ahora puede usar authRepository

  // --- Dependencias de Perfil de Usuario (Ejemplo) ---
  // 1. Obtén la instancia de Databases desde AppConfig
  final databases = AppConfig.databases;

  // 2. Crea y registra UserProfileRepository
  final userProfileRepository = UserProfileRepository(databases);
  Get.put(userProfileRepository);

  // 3. Crea y registra UserProfileController
  Get.put(
    UserProfileController(),
  ); // UserProfileController usará Get.find() para sus dependencias

  // --- Lógica de Arranque de la App ---
  final authController = Get.find<AuthController>();
  // Usa el nombre de método actualizado: checkAuthStatusForAppStart()
  final isLoggedIn = await authController.checkAuthStatusForAppStart();

  runApp(
    GetMaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false, // Útil para desarrollo
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(name: '/home', page: () => HomePage()),
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
        ), // Ruta para el perfil
        // Asegúrate de que todas las páginas referenciadas aquí estén creadas.
      ],
    ),
  );
}
