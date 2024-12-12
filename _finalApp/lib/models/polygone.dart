import 'package:latlong2/latlong.dart';

class Polygone {
  final int id;
  final int zoneId;
  final String geom;

  Polygone({
    required this.id,
    required this.zoneId,
    required this.geom
  });

  // Nouveau getter pour convertir la géométrie en List<LatLng>
  List<LatLng> get points {
    try {
      // Supprime les caractères POLYGON(( et )) de la chaîne WKT
      final cleanGeom = geom.replaceAll('POLYGON((', '').replaceAll('))', '');

      // Divise la chaîne en paires de coordonnées
      final coordinates = cleanGeom.split(',').map((coord) {
        final parts = coord.trim().split(' ');
        // Note: dans le format WKT, longitude vient avant latitude
        return LatLng(
            double.parse(parts[1]), // latitude
            double.parse(parts[0])  // longitude
        );
      }).toList();

      return coordinates;
    } catch (e) {
      print('Erreur lors de la conversion de la géométrie: $e');
      return [];
    }
  }

  // Méthode pour créer une chaîne WKT à partir d'une liste de points
  static String pointsToWKT(List<LatLng> points) {
    if (points.isEmpty) return 'POLYGON EMPTY';

    final coordinates = points.map((point) =>
    '${point.longitude} ${point.latitude}'
    ).join(',');

    return 'POLYGON(($coordinates))';
  }

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

  // Méthode pour créer un nouveau polygone avec des points mis à jour
  Polygone copyWithNewPoints(List<LatLng> newPoints) {
    return Polygone(
      id: id,
      zoneId: zoneId,
      geom: pointsToWKT(newPoints),
    );
  }
}