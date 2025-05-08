import 'package:app_fitness/core/constants/appwrite_constants.dart';
import 'package:appwrite/appwrite.dart';

class AppConfig {
  static final Client _client = Client()
      .setEndpoint(AppwriteConstants.endpoint)
      .setProject(AppwriteConstants.projectId);

  static Client get client => _client;
  static Account get account => Account(_client);
  static Databases get databases =>
      Databases(_client); // No pasar databaseId aquí
  // Puedes agregar inicializaciones para otros servicios
}
