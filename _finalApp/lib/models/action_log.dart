class ActionLog {
  final int? id;
  final int polygoneId;
  final int zoneId;
  final int utilisateurId;
  final String action;
  final String? details;
  final DateTime dateAction;

  const ActionLog({
    this.id,
    required this.polygoneId,
    required this.zoneId,
    required this.utilisateurId,
    required this.action,
    this.details,
    required this.dateAction,
  });

  factory ActionLog.fromMap(Map<String, dynamic> map) {
    return ActionLog(
      id: map['id'] as int?,
      polygoneId: map['polygone_id'] as int,
      zoneId: map['zone_id'] as int,
      utilisateurId: map['utilisateur_id'] as int,
      action: map['action'] as String,
      details: map['details'] as String?,
      dateAction: DateTime.parse(map['date_action'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'polygone_id': polygoneId,
      'zone_id': zoneId,
      'utilisateur_id': utilisateurId,
      'action': action,
      if (details != null) 'details': details,
      'date_action': dateAction.toIso8601String(),
    };
  }

  ActionLog copyWith({
    int? id,
    int? polygoneId,
    int? zoneId,
    int? utilisateurId,
    String? action,
    String? details,
    DateTime? dateAction,
  }) {
    return ActionLog(
      id: id ?? this.id,
      polygoneId: polygoneId ?? this.polygoneId,
      zoneId: zoneId ?? this.zoneId,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      action: action ?? this.action,
      details: details ?? this.details,
      dateAction: dateAction ?? this.dateAction,
    );
  }

  @override
  String toString() {
    return 'ActionLog(id: $id, polygoneId: $polygoneId, zoneId: $zoneId, '
        'utilisateurId: $utilisateurId, action: $action, details: $details, dateAction: $dateAction)';
  }
}