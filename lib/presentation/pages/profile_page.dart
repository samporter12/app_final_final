import 'package:app_fitness/model/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_fitness/controller/user_profile_controller.dart';
import 'package:app_fitness/controller/auth_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileController _profileController =
      Get.find<UserProfileController>();
  final AuthController _authController = Get.find<AuthController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final List<String> _goalOptions = ['muscle_gain', 'deficit', 'maintenance'];
  final List<String> _fitnessLevelOptions = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  String? _selectedGoal;
  String? _selectedFitnessLevel;

  var _profileDisposer;
  bool _isPopulatingFields = false;

  @override
  void initState() {
    super.initState();
    print("ProfilePage initState (${hashCode}): Creando nueva instancia.");

    _profileDisposer = ever(_profileController.userProfile, (
      UserProfileModel? profileFromController,
    ) {
      if (!mounted) {
        print(
          "ProfilePage 'ever' listener (${hashCode}): Widget no montado, ignorando.",
        );
        return;
      }
      print(
        "ProfilePage 'ever' listener (${hashCode}): UserProfileModel cambió. Profile ID: ${profileFromController?.id}, UserID: ${profileFromController?.userId}",
      );
      if (profileFromController?.userId == _authController.getCurrentUserId()) {
        _populateFormFields(profileFromController);
      } else if (profileFromController == null &&
          _authController.getCurrentUserId() == null) {
        _populateFormFields(null);
      } else {
        print(
          "ProfilePage 'ever' listener (${hashCode}): El perfil del controlador no coincide con el usuario actual o es inválido. Auth UserID: ${_authController.getCurrentUserId()}",
        );
      }
    }, condition: () => mounted);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      print(
        "ProfilePage initState (${hashCode}): addPostFrameCallback - Verificando perfil inicial.",
      );
      final currentProfileInController = _profileController.userProfile.value;
      final currentAuthUserId = _authController.getCurrentUserId();

      if (currentAuthUserId != null &&
          (currentProfileInController == null ||
              currentProfileInController.userId != currentAuthUserId ||
              currentProfileInController.id == null ||
              currentProfileInController.id!.isEmpty)) {
        print(
          "ProfilePage initState (${hashCode}): Perfil no coincide o incompleto para $currentAuthUserId, llamando a loadUserProfile.",
        );
        _profileController.loadUserProfile();
      } else if (currentProfileInController != null &&
          currentProfileInController.userId == currentAuthUserId) {
        print(
          "ProfilePage initState (${hashCode}): Perfil ya disponible y correcto en controlador, poblando campos.",
        );
        _populateFormFields(currentProfileInController);
      } else if (currentAuthUserId == null) {
        print(
          "ProfilePage initState (${hashCode}): No hay usuario autenticado. Los campos se mostrarán vacíos o con defaults.",
        );
        _populateFormFields(null);
      }
    });
  }

  void _populateFormFields(UserProfileModel? profile) {
    if (!mounted || _isPopulatingFields) {
      print(
        "ProfilePage _populateFormFields (${hashCode}): Widget no montado o ya poblando, retornando. Mounted: $mounted, IsPopulating: $_isPopulatingFields",
      );
      return;
    }
    _isPopulatingFields = true;
    print(
      "ProfilePage _populateFormFields (${hashCode}): Intentando poblar con profile ID: ${profile?.id}, UserID: ${profile?.userId}",
    );

    final authUserName = _authController.currentUser.value?.name ?? '';

    final newName = profile?.name ?? authUserName;
    if (_nameController.text != newName) _nameController.text = newName;

    final newAge = profile?.age?.toString() ?? '';
    if (_ageController.text != newAge) _ageController.text = newAge;

    final newWeight = profile?.weight?.toString() ?? '';
    if (_weightController.text != newWeight) _weightController.text = newWeight;

    bool needsSetState = false;
    final newGoal = profile?.goal ?? '';
    if (_selectedGoal != newGoal) {
      if (newGoal.isNotEmpty && _goalOptions.contains(newGoal)) {
        _selectedGoal = newGoal;
      } else {
        _selectedGoal = null;
      }
      needsSetState = true;
    }

    final newFitnessLevel = profile?.fitnessLevel ?? '';
    if (_selectedFitnessLevel != newFitnessLevel) {
      if (newFitnessLevel.isNotEmpty &&
          _fitnessLevelOptions.contains(newFitnessLevel)) {
        _selectedFitnessLevel = newFitnessLevel;
      } else {
        _selectedFitnessLevel = null;
      }
      needsSetState = true;
    }

    if (needsSetState) {
      setState(() {});
    }
    _isPopulatingFields = false;
  }

  void _submitProfile() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState!.validate()) {
      if (_selectedGoal == null || _selectedFitnessLevel == null) {
        Get.snackbar(
          "Campos Incompletos",
          "Por favor, selecciona tu objetivo y nivel de fitness.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
        return;
      }
      _profileController.saveOrUpdateProfile(
        name: _nameController.text.trim(),
        age:
            _ageController.text.isNotEmpty
                ? int.tryParse(_ageController.text.trim())
                : null,
        weight:
            _weightController.text.isNotEmpty
                ? double.tryParse(
                  _weightController.text.trim().replaceAll(',', '.'),
                )
                : null,
        goal: _selectedGoal!,
        fitnessLevel: _selectedFitnessLevel!,
      );
    }
  }

  @override
  void dispose() {
    print(
      "ProfilePage dispose (${hashCode}): Eliminando _ProfilePageState y listeners.",
    );
    if (_profileDisposer != null) {
      _profileDisposer();
    }
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _formatDropdownText(String text) {
    if (text.trim().isEmpty) return text;
    String spacedText = text.replaceAll('_', ' ');
    return "${spacedText[0].toUpperCase()}${spacedText.substring(1).toLowerCase()}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print(
      "ProfilePage build (${hashCode}): Construyendo UI. isLoading: ${_profileController.isLoadingProfile.value}, profileError: ${_profileController.profileError.value}, profileID: ${_profileController.userProfile.value?.id}",
    );

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final profile = _profileController.userProfile.value;
          return Text(
            profile != null && profile.id != null && profile.id!.isNotEmpty
                ? 'Actualizar Perfil'
                : 'Crear Perfil Fitness',
            style: TextStyle(color: theme.colorScheme.onPrimary),
          );
        }),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        centerTitle: true,
      ),
      body: Obx(() {
        final profile = _profileController.userProfile.value;
        final isLoading = _profileController.isLoadingProfile.value;
        final error = _profileController.profileError.value;

        if (isLoading &&
            (profile == null ||
                profile.id == null ||
                profile.id!.isEmpty ||
                profile.userId != _authController.getCurrentUserId())) {
          print(
            "ProfilePage build (${hashCode}): Mostrando Loading Indicator (carga inicial o de usuario incorrecto).",
          );
          return const Center(child: CircularProgressIndicator());
        }

        if (error.isNotEmpty &&
            (profile == null ||
                profile.id == null ||
                profile.id!.isEmpty ||
                profile.userId != _authController.getCurrentUserId())) {
          print("ProfilePage build (${hashCode}): Mostrando Error: $error");
          if (error.toLowerCase().contains("texteditingcontroller")) {
            return Center(
              child: Text(
                "Error al preparar la página de perfil.\nPor favor, intenta de nuevo.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error al cargar tu perfil:\n$error",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reintentar Cargar"),
                    onPressed: () => _profileController.loadUserProfile(),
                  ),
                ],
              ),
            ),
          );
        }

        print(
          "ProfilePage build (${hashCode}): Mostrando Formulario. Profile ID: ${profile?.id}, UserID: ${profile?.userId}",
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Edad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final age = int.tryParse(value.trim());
                      if (age == null || age <= 0 || age > 120) {
                        return 'Ingresa una edad válida';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    hintText: 'Ej: 70.5',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*([.,])?\d{0,1}$'),
                    ),
                  ],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final weight = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );
                      if (weight == null || weight <= 0 || weight > 500) {
                        return 'Ingresa un peso válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedGoal,
                  decoration: const InputDecoration(
                    labelText: 'Tu Objetivo Principal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items:
                      _goalOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_formatDropdownText(value)),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    if (mounted)
                      setState(() {
                        _selectedGoal = newValue;
                      });
                  },
                  validator:
                      (value) =>
                          value == null ? 'Selecciona tu objetivo' : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedFitnessLevel,
                  decoration: const InputDecoration(
                    labelText: 'Tu Nivel de Fitness Actual',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fitness_center_outlined),
                  ),
                  items:
                      _fitnessLevelOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_formatDropdownText(value)),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    if (mounted)
                      setState(() {
                        _selectedFitnessLevel = newValue;
                      });
                  },
                  validator:
                      (value) => value == null ? 'Selecciona tu nivel' : null,
                ),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  icon: Obx(
                    () =>
                        _profileController.isLoadingProfile.value
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save_alt_outlined),
                  ),
                  label: Obx(
                    () => Text(
                      _profileController.userProfile.value?.id != null &&
                              _profileController
                                  .userProfile
                                  .value!
                                  .id!
                                  .isNotEmpty
                          ? 'Actualizar Perfil'
                          : 'Guardar y Continuar',
                    ),
                  ),
                  onPressed:
                      _profileController.isLoadingProfile.value
                          ? null
                          : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  if (_profileController.profileError.value.isNotEmpty &&
                      !_profileController.isLoadingProfile.value) {
                    if (!_profileController.profileError.value
                        .toLowerCase()
                        .contains("texteditingcontroller")) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Center(
                          child: Text(
                            "Error al guardar: ${_profileController.profileError.value}",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}
