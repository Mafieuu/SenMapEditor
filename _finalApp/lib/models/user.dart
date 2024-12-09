class User {
  final int id;
  final String nom;
  final String paswd;

  const User({
    required this.id,
    required this.nom,
    required this.paswd,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      nom: map['nom'] as String,
      paswd: map['paswd'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'paswd': paswd,
  };

  User copyWith({
    int? id,
    String? nom,
    String? paswd,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      paswd: paswd ?? this.paswd,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              nom == other.nom &&
              paswd == other.paswd;

  @override
  int get hashCode => Object.hash(id, nom, paswd);

  @override
  String toString() => 'User(id: $id, nom: $nom)';
}