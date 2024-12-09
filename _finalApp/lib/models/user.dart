class User {
  final int? id;
  final String nom;
  final String paswd;

  User({
    this.id,
    required this.nom,
    required this.paswd,
  });

  // Ajoutez un getter qui gère le cas où l'ID est null
  int get safeId => id ?? 0;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      paswd: map['paswd'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'paswd': paswd,
    };
  }
}