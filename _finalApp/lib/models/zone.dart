class Zone {
  final int id;
  final String nom;
  final int? utilisateurId;

  Zone({required this.id, required this.nom, this.utilisateurId});

  factory Zone.fromMap(Map<String, dynamic> map) {
    return Zone(
      id: map['id'],
      nom: map['nom'],
      utilisateurId: map['utilisateur_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'utilisateur_id': utilisateurId,
    };
  }
}