class Polygone {
  final int id;
  final int zoneId;
  final String geom;

  Polygone({required this.id, required this.zoneId, required this.geom});

  factory Polygone.fromMap(Map<String, dynamic> map) {
    return Polygone(
      id: map['id'],
      zoneId: map['zone_id'],
      geom: map['geom'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'geom': geom,
    };
  }
}
