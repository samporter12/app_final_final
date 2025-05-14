import 'package:appwrite/models.dart' as AppwriteModels; // Para el tipo User
import 'package:get/get.dart';
import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';

class AuthController extends GetxController {
  // Inyecta AuthRepository. Asegúrate de que esté registrado en main.dart: Get.put(AuthRepository(AppConfig.account));
  // Si tu AuthController se crea con Get.put(AuthController(authRepositoryInstance)), entonces el constructor está bien.
  // Si usas Get.put(AuthController()), necesitarías Get.find() aquí:
  // final AuthRepository _authRepository = Get.find();
  final AuthRepository
  _authRepository; // Asumiendo que se pasa en el constructor via Get.put

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<AppwriteModels.User?> currentUser = Rx<AppwriteModels.User?>(null);

  AuthController(this._authRepository); // Constructor para la inyección

  @override
  void onInit() {
    super.onInit();
    _initializeUser(); // Carga el usuario al iniciar el controlador
  }

  Future<void> _initializeUser() async {
    // Este método se ejecuta una vez cuando el controlador se inicializa.
    // No es necesario `isLoading` aquí a menos que quieras un spinner global al inicio de la app.
    try {
      currentUser.value = await _authRepository.getCurrentUser();
    } catch (e) {
      // Silenciosamente falla, el usuario simplemente no estará logueado.
      print("Error initializing user: $e");
      currentUser.value = null;
    }
  }

  /// Devuelve el ID del usuario actualmente autenticado, o null si no hay nadie.
  String? getCurrentUserId() {
    return currentUser.value?.$id;
  }

  Future<void> _handleRequest(
    Future<void> Function() requestFunction, {
    Function? onSuccess,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      await requestFunction();
      // Después de una operación de autenticación exitosa, actualiza el usuario.
      currentUser.value = await _authRepository.getCurrentUser();
      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      error.value = e.toString().replaceFirst("Exception: ", "");
      // En caso de error, el usuario actual podría ser null o el anterior.
      // Podrías querer re-evaluar currentUser.value aquí si es necesario.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    await _handleRequest(
      () async => await _authRepository.login(email: email, password: password),
      onSuccess: () => Get.offAll(() => HomePage()),
    );
  }

  Future<void> register(String email, String password, String name) async {
    await _handleRequest(() async {
      await _authRepository.createAccount(
        email: email,
        password: password,
        name: name,
      );
      // Inmediatamente después del registro, intenta iniciar sesión.
      // El _handleRequest se encargará de actualizar currentUser.
      await _authRepository.login(email: email, password: password);
    }, onSuccess: () => Get.offAll(() => HomePage()));
  }

  Future<void> logout() async {
    await _handleRequest(
      () async => await _authRepository.logout(),
      onSuccess: () {
        currentUser.value = null; // Limpia el usuario actual
        // Opcional: Limpiar otros controladores, como el UserProfileController
        // if (Get.isRegistered<UserProfileController>()) {
        //   Get.find<UserProfileController>().clearProfileOnLogout(); // Necesitarías este método
        // }
        Get.offAll(() => LoginPage());
      },
    );
  }

  /// Verifica el estado de autenticación, principalmente para la lógica de arranque en main.dart.
  /// Actualiza `currentUser`.
  Future<bool> checkAuthStatusForAppStart() async {
    isLoading.value = true; // Puede ser útil un breve loading aquí
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
