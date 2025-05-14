import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/model/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_fitness/data/repositories/user_profile_repository.dart';
// Para obtener el userId

class UserProfileController extends GetxController {
  final UserProfileRepository _userProfileRepository = Get.find();
  final AuthController _authController = Get.find();

  final Rx<UserProfileModel?> userProfile = Rx<UserProfileModel?>(null);
  final RxBool isLoadingProfile = false.obs;
  final RxString profileError = ''.obs;

  // Cargar perfil del usuario actual
  Future<void> loadUserProfile() async {
    final userId = _authController.getCurrentUserId();
    if (userId == null) {
      profileError.value = "Usuario no autenticado.";
      userProfile.value = null;
      return;
    }

    isLoadingProfile.value = true;
    profileError.value = '';
    try {
      userProfile.value = await _userProfileRepository.getUserProfile(userId);
      if (userProfile.value == null) {
        profileError.value = "Perfil no encontrado. Puedes crear uno.";
      }
    } catch (e) {
      profileError.value = e.toString().replaceFirst("Exception: ", "");
      userProfile.value = null;
    } finally {
      isLoadingProfile.value = false;
    }
  }

  // Guardar o actualizar perfil
  Future<void> saveOrUpdateProfile({
    required String goal,
    required String fitnessLevel,
    // Agrega otros campos si los tienes, ej: double? weight
  }) async {
    final userId = _authController.getCurrentUserId();
    if (userId == null) {
      profileError.value = "Usuario no autenticado para guardar perfil.";
      return;
    }

    isLoadingProfile.value = true;
    profileError.value = '';

    try {
      UserProfileModel? existingProfile =
          userProfile.value; // El perfil actual cargado

      if (existingProfile == null) {
        // Si no hay perfil cargado, intenta obtenerlo una vez más
        existingProfile = await _userProfileRepository.getUserProfile(userId);
      }

      if (existingProfile != null) {
        // Actualizar perfil existente
        existingProfile.goal = goal;
        existingProfile.fitnessLevel = fitnessLevel;
        // existingProfile.weight = weight;
        await _userProfileRepository.updateUserProfile(existingProfile);
        userProfile.value = existingProfile; // Actualiza el estado local
        Get.snackbar(
          "Perfil Actualizado",
          "Tu información ha sido guardada.",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Crear nuevo perfil
        final newProfile = UserProfileModel(
          userId: userId,
          goal: goal,
          fitnessLevel: fitnessLevel,
          // weight: weight,
        );
        final createdDoc = await _userProfileRepository.saveUserProfile(
          newProfile,
        );
        newProfile.id =
            createdDoc.$id; // Asigna el ID del documento al modelo local
        userProfile.value = newProfile; // Actualiza el estado local
        Get.snackbar(
          "Perfil Guardado",
          "Tu información ha sido creada.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      profileError.value = e.toString().replaceFirst("Exception: ", "");
      Get.snackbar(
        "Error",
        profileError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingProfile.value = false;
    }
  }
}
