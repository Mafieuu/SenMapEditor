import 'package:latlong2/latlong.dart';

class Polygone {
  final int id;
  final int zoneId;
  final String? typePol;
  final String geom;

  Polygone({
    required this.id,
    required this.zoneId,
    this.typePol,
    required this.geom,
  });

  // Getter pour convertir la géométrie en List<LatLng>
  List<LatLng> get points {
    try {
      // Nettoyer et uniformiser la chaîne géométrique
      String cleanGeom = geom
          .replaceAll('POLYGON((', '')
          .replaceAll('))', '')
          .replaceAll('POLYGON (', '')
          .replaceAll(')', '')
          .trim();

      // Séparer les coordonnées
      final coordinates = cleanGeom.split(',').map((coord) {
        // Nettoyer et diviser la chaîne de coordonnées
        final parts = coord.trim().split(RegExp(r'\s+'));

        // Gérer les cas où les coordonnées peuvent être mal formatées
        if (parts.length < 2) {
          print('Coordonnées incomplètes: $coord');
          return null;
        }

        try {
          // Convertir en double en gérant différents formats
          double longitude = double.parse(parts[0].trim());
          double latitude = double.parse(parts[1].trim());

          return LatLng(latitude, longitude);
        } catch (e) {
          print('Erreur de conversion pour les coordonnées: $coord');
          print('Détails de l\'erreur: $e');
          return null;
        }
      }).whereType<LatLng>().toList();

      if (coordinates.isEmpty) {
        throw FormatException('Aucune coordonnée valide trouvée');
      }

      return coordinates;
    } catch (e) {
      print('Erreur lors de la conversion de la géométrie : $e');
      print('Géométrie originale : $geom');
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

  // Méthode de fabrique pour créer un Polygone à partir d'un Map
  factory Polygone.fromMap(Map<String, dynamic> map) {
    return Polygone(
      id: map['id'],
      zoneId: map['zone_id'],
      typePol: map['type_pol'],
      geom: map['geom'],
    );
  }

  // Méthode pour convertir le Polygone en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zone_id': zoneId,
      'type_pol': typePol,
      'geom': geom,
    };
  }

  // Méthode pour créer un nouveau polygone avec des points mis à jour
  Polygone copyWithNewPoints(List<LatLng> newPoints) {
    return Polygone(
      id: id,
      zoneId: zoneId,
      typePol: typePol,
      geom: pointsToWKT(newPoints),
    );
  }

  // Méthode pour convertir le polygone en GeoJSON
  Map<String, dynamic> toGeoJSON() {
    return {
      'type': 'Feature',
      'properties': {
        'id': id,
        'zone_id': zoneId,
        'type_pol': typePol,
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          points.map((point) => [point.longitude, point.latitude]).toList()
        ]
      }
    };
  }

  // Méthode de fabrique pour créer un Polygone à partir de GeoJSON
  factory Polygone.fromGeoJSON(Map<String, dynamic> geoJson) {
    final coordinates = geoJson['geometry']['coordinates'][0];
    final points = coordinates.map<LatLng>((coord) => 
      LatLng(coord[1], coord[0])
    ).toList();

    return Polygone(
      id: geoJson['properties']['id'] ?? 0,
      zoneId: geoJson['properties']['zone_id'] ?? 0,
      typePol: geoJson['properties']['type_pol'],
      geom: pointsToWKT(points),
    );
  }

  // Méthode pour calculer le centre du polygone
  LatLng calculateCenter() {
    if (points.isEmpty) {
      throw StateError('Impossible de calculer le centre d\'un polygone vide');
    }

    double sumLat = 0;
    double sumLon = 0;

    for (var point in points) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }

    return LatLng(
      sumLat / points.length, 
      sumLon / points.length
    );
  }

  // Méthode pour vérifier si un point est à l'intérieur du polygone
  bool containsPoint(LatLng point) {
    int intersectCount = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      if (((points[i].latitude > point.latitude) != 
           (points[j].latitude > point.latitude)) &&
          (point.longitude < (points[j].longitude - points[i].longitude) * 
           (point.latitude - points[i].latitude) / 
           (points[j].latitude - points[i].latitude) + 
           points[i].longitude)) {
        intersectCount++;
      }
    }
    return intersectCount % 2 == 1;
  }
  Polygone copyWith({
    int? id,
    int? zoneId,
    String? typePol,
    String? geom,
  }) {
    return Polygone(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      typePol: typePol ?? this.typePol,
      geom: geom ?? this.geom,
    );
  }
}