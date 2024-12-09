import '../models/user.dart';
import 'database_helper.dart';

class AuthService {
  const AuthService._();
  static const instance = AuthService._();

  Future<User?> login(String nom, String paswd) async {
    if (nom.isEmpty || paswd.isEmpty) {
      throw ArgumentError('Nom et mot de passe ne peuvent pas être vides');
    }
    return await DatabaseHelper.instance.getUser(nom, paswd);
  }

  Future<void> logout() async {
    // Implémentation de la logique de déconnexion
    await Future.delayed(const Duration(milliseconds: 100)); // Simulation
  }

  // Ajout de méthodes utiles
  bool isValidPassword(String password) {
    return password.length >= 6; // Exemple de validation simple
  }

  bool isValidUsername(String username) {
    return username.length >= 3; // Exemple de validation simple
  }
}