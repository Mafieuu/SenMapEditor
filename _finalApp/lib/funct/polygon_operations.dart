// polygon_operations.dart

import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/polygone.dart';
import '../services/database_helper.dart';

class PolygonOperations {
  static Future<bool> mergePolygons({
    required List<int> polygonIds,
    required int zoneId,
    required int userId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      return await db.transaction((txn) async {
        // 1. Récupérer tous les polygones à fusionner
        final List<List<LatLng>> polygonsToMerge = [];
        final List<Map<String, dynamic>> polygonData = [];

        for (int id in polygonIds) {
          final result = await txn.query(
            'polygones',
            where: 'id = ?',
            whereArgs: [id],
          );

          if (result.isEmpty) {
            throw Exception('Polygone $id non trouvé');
          }

          polygonData.add(result.first);
          final points = geometryFromJson(result.first['geom'] as String);
          polygonsToMerge.add(points);
        }

        // 2. Effectuer la fusion
        final List<LatLng> mergedPoints = _mergePolygons(polygonsToMerge);

        // 3. Convertir le résultat en format JSON
        final List<List<double>> coordinates = mergedPoints.map((point) =>
        [point.longitude, point.latitude]
        ).toList();
        final String mergedGeomJson = jsonEncode(coordinates);

        // 4. Créer le nouveau polygone fusionné
        final int newPolygonId = await txn.insert(
          'polygones',
          {
            'zone_id': zoneId,
            'geom': mergedGeomJson,
          },
        );

        // 5. Enregistrer l'action de fusion
        await txn.insert(
          'fusions',
          {
            'nouveau_polygone_id': newPolygonId,
            'zone_id': zoneId,
            'utilisateur_id': userId,
            'polygones_sources': jsonEncode(polygonIds),
            'geom': mergedGeomJson,
            'date_fusion': DateTime.now().toIso8601String(),
          },
        );

        // 6. Supprimer les anciens polygones
        for (int id in polygonIds) {
          await txn.delete(
            'polygones',
            where: 'id = ?',
            whereArgs: [id],
          );
        }

        return true;
      });
    } catch (e) {
      print('Erreur lors de la fusion des polygones: $e');
      return false;
    }
  }

  // Méthodes privées pour la fusion
  static double _calculateDistance(LatLng point1, LatLng point2) {
    return sqrt(
        pow(point1.latitude - point2.latitude, 2) +
            pow(point1.longitude - point2.longitude, 2)
    );
  }

  static bool _arePointsClose(LatLng point1, LatLng point2, {double threshold = 1e-6}) {
    return _calculateDistance(point1, point2) < threshold;
  }

  static List<LatLng> _mergePolygons(List<List<LatLng>> polygons) {
    if (polygons.isEmpty) return [];
    if (polygons.length == 1) return polygons.first;

    Set<LatLng> uniquePoints = {};
    for (var polygon in polygons) {
      uniquePoints.addAll(polygon);
    }

    Map<LatLng, List<LatLng>> pointClusters = {};
    for (var point in uniquePoints) {
      bool merged = false;
      for (var cluster in pointClusters.keys) {
        if (_arePointsClose(point, cluster)) {
          pointClusters[cluster]!.add(point);
          merged = true;
          break;
        }
      }
      if (!merged) {
        pointClusters[point] = [point];
      }
    }

    List<LatLng> mergedPoints = [];
    for (var point in uniquePoints) {
      var representative = pointClusters.keys.firstWhere(
              (k) => pointClusters[k]!.contains(point)
      );
      if (!mergedPoints.contains(representative)) {
        mergedPoints.add(representative);
      }
    }

    return _convexAlgo(mergedPoints);
  }

  static List<LatLng> _convexAlgo(List<LatLng> points) {
    if (points.length <= 3) return points;

    LatLng bottomPoint = points.reduce((a, b) {
      if (a.latitude < b.latitude) return a;
      if (a.latitude > b.latitude) return b;
      return a.longitude < b.longitude ? a : b;
    });

    points.sort((a, b) {
      double angleA = atan2(
          a.latitude - bottomPoint.latitude,
          a.longitude - bottomPoint.longitude
      );
      double angleB = atan2(
          b.latitude - bottomPoint.latitude,
          b.longitude - bottomPoint.longitude
      );
      return angleA.compareTo(angleB);
    });

    List<LatLng> hull = [bottomPoint];
    for (var point in points) {
      while (hull.length > 1 &&
          _crossProduct(hull[hull.length - 2], hull.last, point) <= 0) {
        hull.removeLast();
      }
      hull.add(point);
    }

    return hull;
  }

  static double _crossProduct(LatLng o, LatLng a, LatLng b) {
    return (a.longitude - o.longitude) * (b.latitude - o.latitude) -
        (a.latitude - o.latitude) * (b.longitude - o.longitude);
  }

  static Future<Polygone?> createPolygon({
    required List<LatLng> points,
    required int zoneId,
    required int userId,
  }) async {
    if (points.length < 3) {
      throw Exception('Un polygone doit avoir au moins 3 points');
    }

    try {
      // Convertir les points en format JSON pour stockage
      final List<List<double>> coordinates = points.map((point) =>
      [point.longitude, point.latitude]
      ).toList();

      final String geomJson = jsonEncode(coordinates);

      // Créer le polygone dans la base de données
      final db = await DatabaseHelper.instance.database;

      // Commencer une transaction
      await db.transaction((txn) async {
        // 1. Insérer le polygone
        final polygoneId = await txn.insert(
          'polygones',
          {
            'zone_id': zoneId,
            'geom': geomJson,
          },
        );

        // 2. Enregistrer l'action de création
        await txn.insert(
          'creations',
          {
            'polygone_id': polygoneId,
            'zone_id': zoneId,
            'utilisateur_id': userId,
            'geom': geomJson,
            'date_creation': DateTime.now().toIso8601String(),
          },
        );

        // Retourner le nouveau polygone
        return Polygone(
          id: polygoneId,
          zoneId: zoneId,
          geom: geomJson,
        );
      });
    } catch (e) {
      print('Erreur lors de la création du polygone: $e');
      return null;
    }
    return null;
  }

  static Future<bool> deletePolygon({
    required int polygonId,
    required int zoneId,
    required int userId,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Commencer une transaction
      await db.transaction((txn) async {
        // 1. Récupérer la géométrie du polygone avant suppression
        final polygonData = await txn.query(
          'polygones',
          where: 'id = ?',
          whereArgs: [polygonId],
        );

        if (polygonData.isEmpty) {
          throw Exception('Polygone non trouvé');
        }

        // 2. Enregistrer l'action de suppression
        await txn.insert(
          'suppressions',
          {
            'polygone_id': polygonId,
            'zone_id': zoneId,
            'utilisateur_id': userId,
            'date_suppression': DateTime.now().toIso8601String(),
          },
        );

        // 3. Supprimer le polygone
        await txn.delete(
          'polygones',
          where: 'id = ?',
          whereArgs: [polygonId],
        );
      });

      return true;
    } catch (e) {
      print('Erreur lors de la suppression du polygone: $e');
      return false;
    }
  }

  static Future<bool> modifyPolygon({
    required int polygonId,
    required List<LatLng> newPoints,
    required int zoneId,
    required int userId,
  }) async {
    if (newPoints.length < 3) {
      throw Exception('Un polygone doit avoir au moins 3 points');
    }

    try {
      // Convertir les nouveaux points en format JSON
      final List<List<double>> coordinates = newPoints.map((point) =>
      [point.longitude, point.latitude]
      ).toList();

      final String newGeomJson = jsonEncode(coordinates);

      final db = await DatabaseHelper.instance.database;

      // Commencer une transaction
      await db.transaction((txn) async {
        // 1. Enregistrer la modification
        await txn.insert(
          'modifications',
          {
            'polygone_id': polygonId,
            'zone_id': zoneId,
            'utilisateur_id': userId,
            'nouvelle_geom': newGeomJson,
            'date_modification': DateTime.now().toIso8601String(),
          },
        );

        // 2. Mettre à jour le polygone
        await txn.update(
          'polygones',
          {'geom': newGeomJson},
          where: 'id = ?',
          whereArgs: [polygonId],
        );
      });

      return true;
    } catch (e) {
      print('Erreur lors de la modification du polygone: $e');
      return false;
    }
  }

  // Méthode utilitaire pour convertir JSON en points
  static List<LatLng> geometryFromJson(String geomJson) {
    try {
      final List<dynamic> coordinates = jsonDecode(geomJson);
      return coordinates.map((coord) {
        return LatLng(coord[1] as double, coord[0] as double);
      }).toList();
    } catch (e) {
      print('Erreur lors de la conversion de la géométrie: $e');
      return [];
    }
  }
}