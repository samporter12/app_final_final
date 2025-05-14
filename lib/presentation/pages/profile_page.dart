import 'package:app_fitness/controller/user_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileController _profileController = Get.find();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _fitnessLevelController = TextEditingController();
  // Agrega más controladores si tienes más campos:
  // final TextEditingController _weightController = TextEditingController();

  // Lista de opciones para los desplegables
  final List<String> _goalOptions = ['muscle_gain', 'deficit', 'maintenance'];
  final List<String> _fitnessLevelOptions = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  String? _selectedGoal;
  String? _selectedFitnessLevel;

  @override
  void initState() {
    super.initState();
    // Carga el perfil al iniciar la página si aún no se ha cargado
    if (_profileController.userProfile.value == null &&
        !_profileController.isLoadingProfile.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profileController.loadUserProfile().then((_) {
          _populateFormFields();
        });
      });
    } else {
      _populateFormFields();
    }
  }

  void _populateFormFields() {
    final profile = _profileController.userProfile.value;
    if (profile != null) {
      _selectedGoal = _goalOptions.contains(profile.goal) ? profile.goal : null;
      _selectedFitnessLevel =
          _fitnessLevelOptions.contains(profile.fitnessLevel)
              ? profile.fitnessLevel
              : null;
      // _weightController.text = profile.weight?.toString() ?? '';
      setState(() {}); // Para actualizar los DropdownButton
    }
  }

  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGoal == null || _selectedFitnessLevel == null) {
        Get.snackbar(
          "Campos incompletos",
          "Por favor selecciona objetivo y nivel.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _profileController.saveOrUpdateProfile(
        goal: _selectedGoal!,
        fitnessLevel: _selectedFitnessLevel!,
        // weight: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil Fitness')),
      body: Obx(() {
        if (_profileController.isLoadingProfile.value &&
            _profileController.userProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // Si hay un error y no es 'perfil no encontrado', muéstralo
        if (_profileController.profileError.value.isNotEmpty &&
            !_profileController.profileError.value.contains("encontrado") &&
            _profileController.userProfile.value == null) {
          return Center(
            child: Text('Error: ${_profileController.profileError.value}'),
          );
        }

        // Aunque haya un error de "perfil no encontrado", igual mostramos el formulario
        // para que el usuario pueda crear su perfil.
        // _populateFormFields(); // Llama aquí si no se usa en initState o si puede cambiar

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tu Objetivo:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGoal,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecciona tu objetivo',
                  ),
                  items:
                      _goalOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            GetStringUtils(
                                  value.replaceAll('_', ' '),
                                ).capitalizeFirst ??
                                value,
                          ),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGoal = newValue;
                    });
                  },
                  validator:
                      (value) => value == null ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Tu Nivel de Fitness:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedFitnessLevel,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecciona tu nivel',
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
                      (value) => value == null ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 20),

                // Ejemplo de campo de texto para peso:
                // const Text('Tu Peso (kg):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                // const SizedBox(height: 8),
                // TextFormField(
                //   controller: _weightController,
                //   decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej: 70.5'),
                //   keyboardType: TextInputType.numberWithOptions(decimal: true),
                //   validator: (value) {
                //     if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                //       return 'Ingresa un número válido';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 30),
                Center(
                  child: Obx(() {
                    if (_profileController.isLoadingProfile.value &&
                        _profileController.userProfile.value != null) {
                      // Muestra loading si está actualizando
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      onPressed: _submitProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: Text(
                        _profileController.userProfile.value != null
                            ? 'Actualizar Perfil'
                            : 'Guardar Perfil',
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  if (_profileController.profileError.value.isNotEmpty &&
                      !_profileController.profileError.value.contains(
                        "encontrado",
                      )) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Center(
                        child: Text(
                          _profileController.profileError.value,
                          style: const TextStyle(
                            color: Colors.red,
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
