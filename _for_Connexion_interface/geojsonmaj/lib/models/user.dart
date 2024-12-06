import 'dart:convert';

class User {
  final String firstName;
  final String lastName;
  final String username;
  final String password; // sera haché
  final String zone;
  final Map<String, double> initialCenter;

  User({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.zone,
    required this.initialCenter,
  });

  // Convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'password': password,
      'zone': zone,
      'initialCenter': initialCenter,
    };
  }

  // Créer à partir d'un Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      firstName: map['firstName'],
      lastName: map['lastName'],
      username: map['username'],
      password: map['password'],
      zone: map['zone'],
      initialCenter: Map<String, double>.from(map['initialCenter']),
    );
  }

  // Convertir en JSON
  String toJson() => json.encode(toMap());

  // Créer à partir de JSON
  factory User.fromJson(String source) => User.fromMap(json.decode(source));
}