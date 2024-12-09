class ActionLog {
  final int id;
  final int polygoneId;
  final int zoneId;
  final int utilisateurId;
  final String geom;
  final DateTime dateAction; // Changé en DateTime

  const ActionLog({
    required this.id,
    required this.polygoneId,
    required this.zoneId,
    required this.utilisateurId,
    required this.geom,
    required this.dateAction,
  });

  factory ActionLog.fromMap(Map<String, dynamic> map) {
    return ActionLog(
      id: map['id'] as int,
      polygoneId: map['polygone_id'] as int,
      zoneId: map['zone_id'] as int,
      utilisateurId: map['utilisateur_id'] as int,
      geom: map['geom'] as String,
      dateAction: DateTime.parse(map['date_action'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'polygone_id': polygoneId,
      'zone_id': zoneId,
      'utilisateur_id': utilisateurId,
      'geom': geom,
      'date_action': dateAction.toIso8601String(),
    };
  }

  ActionLog copyWith({
    int? id,
    int? polygoneId,
    int? zoneId,
    int? utilisateurId,
    String? geom,
    DateTime? dateAction,
  }) {
    return ActionLog(
      id: id ?? this.id,
      polygoneId: polygoneId ?? this.polygoneId,
      zoneId: zoneId ?? this.zoneId,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      geom: geom ?? this.geom,
      dateAction: dateAction ?? this.dateAction,
    );
  }

  @override
  String toString() {
    return 'ActionLog(id: $id, polygoneId: $polygoneId, zoneId: $zoneId, '
        'utilisateurId: $utilisateurId, dateAction: $dateAction)';
  }
}