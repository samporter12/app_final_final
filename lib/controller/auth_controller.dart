import 'package:app_fitness/data/repositories/auth_repository.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';
import 'package:app_fitness/presentation/pages/login_page.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  AuthController(this._authRepository);

  Future<void> _handleRequest(Future<void> Function() request) async {
    try {
      isLoading.value = true;
      error.value = '';
      await request();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    await _handleRequest(() async {
      await _authRepository.login(email: email, password: password);
      Get.offAll(() => HomePage());
    });
  }

  Future<void> register(String email, String password, String name) async {
    await _handleRequest(() async {
      await _authRepository.createAccount(
        email: email,
        password: password,
        name: name,
      );
      await login(email, password); // Loguear al usuario después del registro
    });
  }

  Future<void> logout() async {
    await _handleRequest(() async {
      await _authRepository.logout();
      Get.offAll(() => LoginPage());
    });
  }

  Future<bool> checkAuth() async {
    isLoading.value = true;
    try {
      return await _authRepository.isLoggedIn();
    } catch (e) {
      error.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
