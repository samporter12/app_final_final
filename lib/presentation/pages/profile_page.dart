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

  final List<String> _goalOptions = [
    'Ganancia Muscular',
    'Deficit Calorico',
    'Mantener estado actual',
  ];
  final List<String> _fitnessLevelOptions = [
    'Principiante',
    'Intermedia',
    'Avanzado',
  ];

  String? _selectedGoal;
  String? _selectedFitnessLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFormFields();
    });
  }

  void _populateFormFields() {
    final profile = _profileController.userProfile.value;
    if (profile != null) {
      _nameController.text = profile.name;
      _ageController.text = profile.age?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';

      if (profile.goal.isNotEmpty && _goalOptions.contains(profile.goal)) {
        _selectedGoal = profile.goal;
      } else if (_goalOptions.isNotEmpty) {}

      if (profile.fitnessLevel.isNotEmpty &&
          _fitnessLevelOptions.contains(profile.fitnessLevel)) {
        _selectedFitnessLevel = profile.fitnessLevel;
      } else if (_fitnessLevelOptions.isNotEmpty) {}
      if (mounted) {
        setState(() {});
      }
    } else {
      _nameController.text = _authController.currentUser.value?.name ?? '';
    }
  }

  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGoal == null || _selectedFitnessLevel == null) {
        Get.snackbar(
          "Campos Incompletos",
          "Por favor, selecciona tu objetivo y nivel de fitness.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent,
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
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ever(_profileController.userProfile, (_) => _populateFormFields());

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            _profileController.userProfile.value?.id != null &&
                    _profileController.userProfile.value!.id!.isNotEmpty
                ? 'Actualizar Perfil'
                : 'Crear Perfil Fitness',
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (_profileController.isLoadingProfile.value &&
            _profileController.userProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si hubo un error al cargar el perfil, mostrarlo
        if (_profileController.profileError.value.isNotEmpty &&
            _profileController.userProfile.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error al cargar tu perfil:\n${_profileController.profileError.value}",
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
                    return null; // Edad es opcional
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
                          child: Text(
                            value.replaceAll('_', ' ').capitalizeFirst ?? value,
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
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
                          child: Text(value.capitalizeFirst ?? value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
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
                  label: Text(
                    _profileController.userProfile.value?.id != null &&
                            _profileController.userProfile.value!.id!.isNotEmpty
                        ? 'Actualizar Perfil'
                        : 'Guardar y Continuar',
                  ),
                  onPressed:
                      _profileController.isLoadingProfile.value
                          ? null
                          : _submitProfile,
                  style: ElevatedButton.styleFrom(
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
