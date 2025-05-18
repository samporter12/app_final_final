// lib/controller/user_profile_controller.dart
import 'package:app_fitness/model/user_profile_model.dart';
import 'package:flutter/material.dart'; // Para Colors en Get.snackbar
import 'package:get/get.dart';
import 'package:app_fitness/data/repositories/user_profile_repository.dart';
import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/presentation/pages/home_page.dart'; // Para la redirección

class UserProfileController extends GetxController {
  final UserProfileRepository _userProfileRepository =
      Get.find<UserProfileRepository>();
  final AuthController _authController = Get.find<AuthController>();

  final Rx<UserProfileModel?> userProfile = Rx<UserProfileModel?>(null);
  final RxBool isLoadingProfile = false.obs;
  final RxString profileError = ''.obs;

  // No es necesario onInit aquí si loadUserProfile se llama explícitamente
  // cuando se necesita (ej. en AuthController o al entrar a ProfilePage/HomePage).

  /// Carga el perfil del usuario actualmente autenticado.
  Future<void> loadUserProfile() async {
    final userId = _authController.getCurrentUserId();
    if (userId == null) {
      profileError.value =
          "Usuario no autenticado. No se puede cargar el perfil.";
      userProfile.value = null;
      return;
    }

    isLoadingProfile.value = true;
    profileError.value = '';
    try {
      userProfile.value = await _userProfileRepository.getUserProfile(userId);
      if (userProfile.value == null) {
        print(
          "Perfil no encontrado para el usuario $userId. Puede ser la primera vez.",
        );
        // No se considera un error fatal aquí, la UI puede manejar este estado.
      } else {
        print(
          "Perfil cargado para el usuario $userId: ${userProfile.value!.goal}",
        );
      }
    } catch (e) {
      profileError.value = e.toString().replaceFirst("Exception: ", "");
      userProfile.value =
          null; // Asegurarse de limpiar el perfil en caso de error
      print("Error al cargar el perfil del usuario: ${profileError.value}");
    } finally {
      isLoadingProfile.value = false;
    }
  }

  /// Guarda un nuevo perfil o actualiza uno existente.
  /// Redirige a HomePage después de una operación exitosa.
  Future<void> saveOrUpdateProfile({
    required String goal,
    required String fitnessLevel,
    // Puedes añadir más campos aquí si tu UserProfileModel los tiene (ej. peso, altura)
    // double? weight,
  }) async {
    final userId = _authController.getCurrentUserId();
    if (userId == null) {
      profileError.value =
          "Usuario no autenticado. No se puede guardar el perfil.";
      Get.snackbar(
        "Error de Autenticación",
        profileError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoadingProfile.value = true;
    profileError.value = '';

    try {
      // Intenta obtener el perfil actual para saber si estamos creando o actualizando
      // y para obtener el ID del documento si estamos actualizando.
      UserProfileModel? existingProfile = userProfile.value;
      // Si el perfil local es null o no tiene ID de documento, intenta cargarlo desde el repositorio.
      // Esto es importante si el usuario llega a ProfilePage sin que `loadUserProfile` se haya completado
      // o si se quiere asegurar de tener la versión más reciente antes de actualizar.
      if (existingProfile == null || existingProfile.id == null) {
        print(
          "Perfil local no disponible o sin ID, intentando cargar desde el repositorio...",
        );
        existingProfile = await _userProfileRepository.getUserProfile(userId);
        // Si se carga desde el repo, actualiza el estado local reactivo
        if (existingProfile != null) {
          userProfile.value = existingProfile;
        }
      }

      if (existingProfile != null && existingProfile.id != null) {
        // --- Actualizar Perfil Existente ---
        print("Actualizando perfil existente con ID: ${existingProfile.id}");
        // Actualiza los campos del modelo local
        existingProfile.goal = goal;
        existingProfile.fitnessLevel = fitnessLevel;
        // existingProfile.weight = weight; // Ejemplo

        await _userProfileRepository.updateUserProfile(existingProfile);
        userProfile.value =
            existingProfile; // Refresca el estado local con el perfil actualizado (aunque ya lo modificamos)
        Get.snackbar(
          "Perfil Actualizado",
          "Tu información ha sido guardada correctamente.",
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAll(() => HomePage()); // Redirigir a HomePage
      } else {
        // --- Crear Nuevo Perfil ---
        print("Creando nuevo perfil para el usuario ID: $userId");
        final newProfile = UserProfileModel(
          userId: userId, // El ID del usuario autenticado
          goal: goal,
          fitnessLevel: fitnessLevel,
          // weight: weight, // Ejemplo
        );
        final createdDocument = await _userProfileRepository.saveUserProfile(
          newProfile,
        );
        newProfile.id =
            createdDocument
                .$id; // Asigna el ID del documento de Appwrite al modelo
        newProfile.createdAt = DateTime.tryParse(
          createdDocument.$createdAt,
        ); // Asigna la fecha de creación
        newProfile.updatedAt = DateTime.tryParse(
          createdDocument.$updatedAt,
        ); // Asigna la fecha de actualización

        userProfile.value =
            newProfile; // Actualiza el estado local con el nuevo perfil
        Get.snackbar(
          "Perfil Guardado",
          "¡Tu perfil ha sido creado exitosamente!",
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAll(() => HomePage()); // Redirigir a HomePage
      }
    } catch (e) {
      profileError.value = e.toString().replaceFirst("Exception: ", "");
      print("Error al guardar/actualizar el perfil: ${profileError.value}");
      Get.snackbar(
        "Error de Perfil",
        profileError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingProfile.value = false;
    }
  }

  /// Limpia los datos del perfil al cerrar sesión.
  void clearProfileOnLogout() {
    userProfile.value = null;
    profileError.value = '';
    isLoadingProfile.value = false; // Asegurarse de resetear el estado de carga
    print("Perfil de usuario limpiado al cerrar sesión.");
  }
}
