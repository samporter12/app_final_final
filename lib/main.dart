import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/core/config/app_config.dart'; // Asegúrate de tener esta importación
import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';
import 'package:app_fitness/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtén la instancia de Account desde AppConfig
  final account = AppConfig.account;

  // Crea la instancia de AuthRepository PASANDO la instancia de Account DE FORMA POSICIONAL
  final authRepository = AuthRepository(account);

  Get.put(AuthController(authRepository)); // Inicializa el AuthController

  final authController = Get.find<AuthController>();
  final isLoggedIn = await authController.checkAuth();

  runApp(
    GetMaterialApp(
      title: 'Fitness App',
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginPage()),
        GetPage(name: '/register', page: () => RegisterPage()),
        GetPage(
          name: '/home',
          page: () => HomePage(),
        ), // Asegúrate de tener esta ruta
      ],
    ),
  );
}
