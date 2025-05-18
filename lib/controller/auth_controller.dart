// lib/controller/auth_controller.dart
import 'package:app_fitness/controller/fitness_controller.dart';
import 'package:appwrite/models.dart' as AppwriteModels;
import 'package:get/get.dart';
import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';
import 'package:app_fitness/presentation/pages/profile_page.dart'; // Necesario para la redirección
import 'package:app_fitness/controller/user_profile_controller.dart'; // Necesario para verificar perfil

class AuthController extends GetxController {
  final AuthRepository _authRepository;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<AppwriteModels.User?> currentUser = Rx<AppwriteModels.User?>(null);

  AuthController(this._authRepository);

  @override
  void onInit() {
    super.onInit();
    _initializeUser(); // Carga el usuario al iniciar el controlador
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
    Function?
    onError, // Callback para manejar errores específicos si es necesario
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      await requestFunction();
      // Actualizar el usuario actual después de la operación
      currentUser.value = await _authRepository.getCurrentUser();
      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      error.value = e.toString().replaceFirst("Exception: ", "");
      if (onError != null) {
        onError();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    await _handleRequest(
      () async => await _authRepository.login(email: email, password: password),
      onSuccess: () {
        // Después de un login normal, verificar perfil también podría ser una opción
        // o simplemente ir a HomePage y que HomePage maneje la lógica del perfil.
        // Por ahora, mantenemos la redirección a HomePage y HomePage se encarga.
        Get.offAll(() => HomePage());
      },
    );
  }

  Future<void> register(String email, String password, String name) async {
    await _handleRequest(
      () async {
        // 1. Crear la cuenta del usuario
        await _authRepository.createAccount(
          email: email,
          password: password,
          name: name,
        );
        // 2. Iniciar sesión automáticamente con el usuario recién creado
        await _authRepository.login(email: email, password: password);
      },
      onSuccess: () async {
        // 3. Después del login exitoso tras el registro:
        // Asegurarse de que UserProfileController esté disponible
        if (!Get.isRegistered<UserProfileController>()) {
          // Esto no debería pasar si main.dart está bien configurado
          Get.snackbar(
            "Error de Configuración",
            "UserProfileController no encontrado.",
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAll(() => LoginPage()); // Fallback seguro
          return;
        }
        final userProfileController = Get.find<UserProfileController>();
        final userId =
            getCurrentUserId(); // Obtener el ID del usuario recién logueado

        if (userId != null) {
          // 4. Intentar cargar el perfil del usuario para ver si ya existe (no debería para un nuevo registro)
          await userProfileController
              .loadUserProfile(); // Este método usa el userId del AuthController

          // 5. Redirigir basado en la existencia del perfil
          if (userProfileController.userProfile.value == null) {
            // Si no hay perfil (userProfile.value es null),
            // o si hubo un error específico de "perfil no encontrado",
            // redirigir a ProfilePage para que el usuario lo cree.
            print(
              "Usuario nuevo o perfil no encontrado. Redirigiendo a ProfilePage.",
            );
            Get.offAll(() => ProfilePage());
          } else {
            // Si el perfil ya existe (caso muy raro para un nuevo registro, pero es un fallback), ir a HomePage.
            print("Perfil encontrado. Redirigiendo a HomePage.");
            Get.offAll(() => HomePage());
          }
        } else {
          // No se pudo obtener el userId después del login, algo salió mal.
          Get.snackbar(
            "Error de Sesión",
            "No se pudo verificar tu sesión. Por favor, inicia sesión.",
            snackPosition: SnackPosition.BOTTOM,
          );
          Get.offAll(() => LoginPage());
        }
      },
      onError: () {
        // Si el registro o el login automático fallan, el usuario se queda en la página de registro.
        // El error se mostrará en la UI gracias a `error.value` que se actualiza en _handleRequest.
        print("Error durante el registro o login automático: ${error.value}");
      },
    );
  }

  Future<void> logout() async {
    await _handleRequest(
      () async => await _authRepository.logout(),
      onSuccess: () {
        currentUser.value = null; // Limpiar el usuario actual
        // Limpiar también el perfil del usuario y datos de fitness
        if (Get.isRegistered<UserProfileController>()) {
          Get.find<UserProfileController>().clearProfileOnLogout();
        }
        if (Get.isRegistered<FitnessController>()) {
          // Asumiendo que tienes FitnessController
          Get.find<FitnessController>().clearFitnessDataOnLogout();
        }
        Get.offAll(() => LoginPage());
      },
    );
  }

  /// Verifica el estado de autenticación al iniciar la aplicación.
  Future<bool> checkAuthStatusForAppStart() async {
    isLoading.value = true;
    try {
      final user = await _authRepository.getCurrentUser();
      currentUser.value = user;
      return user != null;
    } catch (e) {
      error.value = e.toString().replaceFirst("Exception: ", "");
      currentUser.value = null;
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
