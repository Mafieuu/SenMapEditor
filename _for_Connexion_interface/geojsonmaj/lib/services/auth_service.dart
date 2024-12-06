import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

class AuthService {
  // Chemin du fichier des utilisateurs
  Future<String> get _localUserFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/users.json';
  }

  // Hacher le mot de passe
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Inscription
  Future<bool> register(User user) async {
    try {
      final userFile = File(await _localUserFilePath);
      List<dynamic> users = [];

      // Lire les utilisateurs existants
      if (await userFile.exists()) {
        final content = await userFile.readAsString();
        users = json.decode(content);
      }

      // Vérifier si le username existe déjà
      if (users.any((u) => u['username'] == user.username)) {
        return false;
      }

      // Hasher le mot de passe
      final userMap = user.toMap();
      userMap['password'] = _hashPassword(userMap['password']);

      // Ajouter le nouvel utilisateur
      users.add(userMap);

      // Écrire dans le fichier
      await userFile.writeAsString(json.encode(users));
      return true;
    } catch (e) {
      print('Erreur lors de l\'inscription : $e');
      return false;
    }
  }

  // Connexion
  Future<User?> login(String username, String password) async {
    try {
      final userFile = File(await _localUserFilePath);

      // Vérifier si le fichier existe
      if (!await userFile.exists()) {
        return null;
      }

      final content = await userFile.readAsString();
      List<dynamic> users = json.decode(content);

      // Rechercher l'utilisateur
      final hashedPassword = _hashPassword(password);
      final userMap = users.firstWhere(
              (u) => u['username'] == username && u['password'] == hashedPassword,
          orElse: () => null
      );

      return userMap != null ? User.fromMap(userMap) : null;
    } catch (e) {
      print('Erreur de connexion : $e');
      return null;
    }
  }

  // Vérifier la présence du fichier GeoJSON local
  Future<bool> checkLocalGeojsonFile(String zone) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$zone.geojson');
    return await file.exists();
  }

  // Déconnexion (vide pour le moment)
  Future<void> logout() async {
    // Logique de déconnexion si nécessaire
  }
}