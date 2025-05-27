import 'package:app_fitness/controller/fitness_controller.dart';
import 'package:appwrite/models.dart' as AppwriteModels;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';
import 'package:app_fitness/presentation/pages/profile_page.dart';
import 'package:app_fitness/controller/user_profile_controller.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<AppwriteModels.User?> currentUser = Rx<AppwriteModels.User?>(null);

  AuthController(this._authRepository);

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      currentUser.value = await _authRepository.getCurrentUser();
    } catch (e) {
      print("Error initializing user: $e");
      currentUser.value = null;
    }
  }

  String? getCurrentUserId() {
    return currentUser.value?.$id;
  }

  Future<void> _handleRequest(
    Future<void> Function() requestFunction, {
    Function? onSuccess,
    Function? onError,
    bool updateUserStateAfterSuccess = true,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      await requestFunction();

      if (updateUserStateAfterSuccess) {
        currentUser.value = await _authRepository.getCurrentUser();
      }

      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      error.value = e.toString().replaceFirst("Exception: ", "");
      if (onError != null) {
        onError();
      } else {
        print("Error en _handleRequest: ${error.value}");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    await _handleRequest(
      () async => await _authRepository.login(email: email, password: password),
      onSuccess: () {
        Get.offAll(() => HomePage());
      },
    );
  }

  Future<void> register(String email, String password, String name) async {
    await _handleRequest(
      () async {
        await _authRepository.createAccount(
          email: email,
          password: password,
          name: name,
        );
        await _authRepository.login(email: email, password: password);
      },
      onSuccess: () async {
        print("Registro y login automático exitosos, verificando perfil...");
        if (!Get.isRegistered<UserProfileController>()) {
          Get.snackbar(
            "Error de Configuración",
            "UserProfileController no encontrado.",
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAll(() => LoginPage());
          return;
        }
        final userProfileController = Get.find<UserProfileController>();
        final userId = getCurrentUserId();
        print("UserID para verificar perfil: $userId");

        if (userId != null) {
          await userProfileController.loadUserProfile();

          final profile = userProfileController.userProfile.value;
          print(
            "DEBUG AuthController: Perfil obtenido de UserProfileController: ${profile?.toJson()}",
          );
          print("DEBUG AuthController: ID del perfil obtenido: ${profile?.id}");

          bool needsProfileCreation = true;

          if (profile != null) {
            if (profile.id != null && profile.id!.isNotEmpty) {
              needsProfileCreation = false;
            }
          }

          if (needsProfileCreation) {
            print(
              "Usuario nuevo o perfil sin ID de DB válido. Redirigiendo a ProfilePage.",
            );
            Get.offAll(() => ProfilePage());
          } else {
            print(
              "Perfil encontrado con ID de DB (${profile?.id}). Redirigiendo a HomePage.",
            );
            Get.offAll(() => HomePage());
          }
        } else {
          Get.snackbar(
            "Error de Sesión",
            "No se pudo verificar tu sesión. Por favor, inicia sesión.",
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAll(() => LoginPage());
        }
      },
      onError: () {
        print("Error durante el registro o login automático: ${error.value}");
      },
    );
  }

  Future<void> logout() async {
    isLoading.value = true;
    error.value = '';
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await _authRepository.logout();

      currentUser.value = null;

      Get.offAll(() => LoginPage()); // Navegar primero

      // Limpiar otros controladores DESPUÉS de la navegación principal.
      // Usar addPostFrameCallback para ejecutar después de que el frame actual se complete.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<UserProfileController>()) {
          Get.find<UserProfileController>().clearProfileOnLogout();
        }
        if (Get.isRegistered<FitnessController>()) {
          Get.find<FitnessController>().clearFitnessDataOnLogout();
        }
        print(
          "Controladores de perfil y fitness limpiados post-logout y navegación.",
        );
      });
    } catch (e) {
      error.value = e.toString().replaceFirst("Exception: ", "");
      print("Error durante el logout: ${error.value}");

      if (!error.value.toLowerCase().contains("texteditingcontroller") &&
          !error.value.toLowerCase().contains("missing scope (account)")) {
        Get.snackbar(
          "Error de Logout",
          "No se pudo cerrar la sesión.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // Si el error fue capturado y la navegación principal no ocurrió, intentar forzarla.
      // Asegúrate de que '/login' sea el nombre de tu ruta para LoginPage en getPages.
      if (Get.currentRoute != '/login') {
        Get.offAll(() => LoginPage());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> checkAuthStatusForAppStart() async {
    isLoading.value = true;
    try {
      final user = await _authRepository.getCurrentUser();
      currentUser.value = user;
      return user != null;
    } catch (e) {
      if (!e.toString().toLowerCase().contains("missing scope (account)")) {
        error.value = e.toString().replaceFirst("Exception: ", "");
      }
      print("checkAuthStatusForAppStart error (puede ser normal): $e");
      currentUser.value = null;
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
