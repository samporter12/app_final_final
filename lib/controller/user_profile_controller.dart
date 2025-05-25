// lib/controller/user_profile_controller.dart
import 'package:app_fitness/model/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_fitness/data/repositories/user_profile_repository.dart';
import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/presentation/pages/home_page.dart';

class UserProfileController extends GetxController {
  final UserProfileRepository _userProfileRepository =
      Get.find<UserProfileRepository>();
  final AuthController _authController = Get.find<AuthController>();

  final Rx<UserProfileModel?> userProfile = Rx<UserProfileModel?>(null);
  final RxBool isLoadingProfile = false.obs;
  final RxString profileError = ''.obs;

  Future<void> loadUserProfile() async {
    final userId = _authController.getCurrentUserId();
    final authUserName = _authController.currentUser.value?.name ?? '';

    if (userId == null) {
      profileError.value =
          "Usuario no autenticado. No se puede cargar el perfil.";
      userProfile.value = null;
      return;
    }

    isLoadingProfile.value = true;
    profileError.value = '';
    try {
      UserProfileModel? loadedProfile = await _userProfileRepository
          .getUserProfile(userId);

      if (loadedProfile == null) {
        print(
          "Perfil no encontrado para el usuario $userId. Puede ser la primera vez.",
        );
        // Si es la primera vez y no hay perfil, creamos una instancia local
        // SIN ID de Appwrite. El campo 'id' será null.
        // Esto permite que ProfilePage muestre el nombre si viene de Auth,
        // y que AuthController identifique que es un perfil "no guardado".
        userProfile.value = UserProfileModel(
          userId: userId,
          name: authUserName.isNotEmpty ? authUserName : "Usuario",
          goal: '', // Dejar vacío para que el usuario lo llene
          fitnessLevel: '', // Dejar vacío
          // age y weight serán null por defecto
          // id, createdAt, updatedAt también serán null
        );
      } else {
        // Si el perfil existe pero el nombre está vacío (caso raro), actualízalo con el de Auth si está disponible
        if (loadedProfile.name.isEmpty && authUserName.isNotEmpty) {
          loadedProfile.name = authUserName;
        }
        userProfile.value = loadedProfile;
        print(
          "Perfil cargado para el usuario $userId. ID del perfil: ${userProfile.value!.id}, Objetivo: ${userProfile.value!.goal}",
        );
      }
    } catch (e) {
      profileError.value = e.toString().replaceFirst("Exception: ", "");
      userProfile.value = null;
      print("Error al cargar el perfil del usuario: ${profileError.value}");
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> saveOrUpdateProfile({
    required String name,
    int? age,
    double? weight,
    required String goal,
    required String fitnessLevel,
  }) async {
    final userId = _authController.getCurrentUserId();
    final authUserName = _authController.currentUser.value?.name ?? '';

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
      UserProfileModel? existingProfileDataFromState = userProfile.value;

      // Verifica si el perfil en el estado ya tiene un ID de DB,
      // si no, intenta cargarlo de nuevo para asegurar que no haya una creación duplicada.
      if (existingProfileDataFromState == null ||
          existingProfileDataFromState.id == null ||
          existingProfileDataFromState.id!.isEmpty) {
        print("Perfil local no tiene ID de DB, verificando en repositorio...");
        existingProfileDataFromState = await _userProfileRepository
            .getUserProfile(userId);
        if (existingProfileDataFromState != null) {
          userProfile.value =
              existingProfileDataFromState; // Actualizar el estado global
        }
      }

      final String profileName =
          name.isNotEmpty
              ? name
              : (authUserName.isNotEmpty ? authUserName : "Usuario");

      if (existingProfileDataFromState != null &&
          existingProfileDataFromState.id != null &&
          existingProfileDataFromState.id!.isNotEmpty) {
        // Actualizar Perfil Existente
        print(
          "Actualizando perfil existente con ID: ${existingProfileDataFromState.id}",
        );
        existingProfileDataFromState.name = profileName;
        existingProfileDataFromState.age = age;
        existingProfileDataFromState.weight = weight;
        existingProfileDataFromState.goal = goal;
        existingProfileDataFromState.fitnessLevel = fitnessLevel;

        await _userProfileRepository.updateUserProfile(
          existingProfileDataFromState,
        );
        userProfile.value = existingProfileDataFromState;
        Get.snackbar(
          "Perfil Actualizado",
          "Tu información ha sido guardada correctamente.",
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAll(() => HomePage());
      } else {
        // Crear Nuevo Perfil
        print("Creando nuevo perfil para el usuario ID: $userId");
        final newProfile = UserProfileModel(
          userId: userId,
          name: profileName,
          age: age,
          weight: weight,
          goal: goal,
          fitnessLevel: fitnessLevel,
        );
        final createdDocument = await _userProfileRepository.saveUserProfile(
          newProfile,
        );
        newProfile.id = createdDocument.$id;
        newProfile.createdAt = DateTime.tryParse(
          createdDocument.$createdAt ?? '',
        );
        newProfile.updatedAt = DateTime.tryParse(
          createdDocument.$updatedAt ?? '',
        );

        userProfile.value = newProfile;
        Get.snackbar(
          "Perfil Guardado",
          "¡Tu perfil ha sido creado exitosamente!",
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAll(() => HomePage());
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

  void clearProfileOnLogout() {
    userProfile.value = null;
    profileError.value = '';
    isLoadingProfile.value = false;
    print("Perfil de usuario limpiado al cerrar sesión.");
  }
}
