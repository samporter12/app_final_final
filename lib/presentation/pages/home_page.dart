import 'package:app_fitness/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authController.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Aquí encontrarás recomendaciones personalizadas de rutinas y recetas fitness para alcanzar tus objetivos.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            Text(
              'Rutinas Recomendadas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Aquí podrías mostrar una lista de rutinas recomendadas
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 3, // Ejemplo de 3 rutinas
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('Rutina de ejemplo ${index + 1}'),
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            Text(
              'Recetas Recomendadas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Aquí podrías mostrar una lista de recetas recomendadas
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 2, // Ejemplo de 2 recetas
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('Receta de ejemplo ${index + 1}'),
                  ),
                );
              },
            ),
            SizedBox(height: 30),
            Text(
              'Próximamente: Más funcionalidades emocionantes!',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
