class User {
  final int id;
  final String nom;
  final int? zoneId;

  User({
    required this.id, 
    required this.nom, 
    this.zoneId
  });

  factory User.fromMap(Map map) {
    return User(
      id: map['id'],
      nom: map['nom'],
      zoneId: map['zone_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'zone_id': zoneId,
    };
  }
}