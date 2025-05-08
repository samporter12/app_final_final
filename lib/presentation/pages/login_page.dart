import 'package:app_fitness/controller/auth_controller.dart';
import 'package:app_fitness/presentation/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Sesión')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Obx(
                  () =>
                      _authController.error.value.isNotEmpty
                          ? Text(
                            _authController.error.value,
                            style: TextStyle(color: Colors.red),
                          )
                          : SizedBox.shrink(),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator:
                      (value) => value!.contains('@') ? null : 'Email inválido',
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator:
                      (value) =>
                          value!.length >= 6 ? null : 'Mínimo 6 caracteres',
                ),
                SizedBox(height: 24.0),
                Obx(
                  () => ElevatedButton(
                    onPressed:
                        _authController.isLoading.value
                            ? null
                            : () {
                              if (_formKey.currentState!.validate()) {
                                _authController.login(
                                  _emailController.text,
                                  _passwordController.text,
                                );
                              }
                            },
                    child:
                        _authController.isLoading.value
                            ? CircularProgressIndicator()
                            : Text('Iniciar Sesión'),
                  ),
                ),
                SizedBox(height: 16.0),
                TextButton(
                  onPressed: () => Get.off(() => RegisterPage()),
                  child: Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
