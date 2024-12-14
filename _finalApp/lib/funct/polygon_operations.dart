import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/polygone.dart';
import '../models/action_log.dart';
import '../services/database_helper.dart';

class PolygonOperations {
  // Fusion de polygones
  static Future<Polygone?> mergePolygons({
    required List<int> polygonIds,
    required int zoneId,
    required int userId,
  }) async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      return await db.transaction((txn) async {
        // 1. Récupérer tous les polygones à fusionner
        final List<List<LatLng>> polygonsToMerge = [];
        final List<Map<String, dynamic>> polygonData = [];

        for (int id in polygonIds) {
          final result = await txn.query(
            DatabaseHelper.tablePolygons,
            where: 'id = ?',
            whereArgs: [id],
          );

          if (result.isEmpty) {
            throw Exception('Polygone $id non trouvé');
          }

          polygonData.add(result.first);
          final polygone = Polygone.fromMap(result.first);
          polygonsToMerge.add(polygone.points);
        }

        // 2. Effectuer la fusion
        final List<LatLng> mergedPoints = _mergePolygons(polygonsToMerge);

        // 3. Convertir le résultat en WKT
        final String mergedGeom = Polygone.pointsToWKT(mergedPoints);

        // 4. Créer le nouveau polygone fusionné
        final Polygone newPolygone = Polygone(
          id: DateTime.now().millisecondsSinceEpoch, // Temporaire
          zoneId: zoneId,
          geom: mergedGeom,
          typePol: 'merged',
        );

        final int newPolygonId = await dbHelper.insertPolygone(newPolygone);

        // 5. Enregistrer l'action de fusion
        await dbHelper.insertActionLog(
          ActionLog(
            polygoneId: newPolygonId,
            zoneId: zoneId,
            utilisateurId: userId,
            action: 'fusion',
            details: jsonEncode({
              'polygones_sources': polygonIds,
            }),
            dateAction: DateTime.now(),
          ),
        );

        // 6. Supprimer les anciens polygones
        for (int id in polygonIds) {
          await txn.delete(
            DatabaseHelper.tablePolygons,
            where: 'id = ?',
            whereArgs: [id],
          );
        }

        return newPolygone.copyWith(id: newPolygonId);
      });
    } catch (e) {
      print('Erreur lors de la fusion des polygones: $e');
      return null;
    }
  }

  // Création d'un nouveau polygone
  static Future<Polygone?> createPolygon({
    required List<LatLng> points,
    required int zoneId,
    required int userId,
    String? typePol,
  }) async {
    if (points.length < 3) {
      throw Exception('Un polygone doit avoir au moins 3 points');
    }

    try {
      // Convertir les points en WKT
      final String geom = Polygone.pointsToWKT(points);

      // Créer le polygone
      final Polygone newPolygone = Polygone(
        id: DateTime.now().millisecondsSinceEpoch, // Temporaire
        zoneId: zoneId,
        geom: geom,
        typePol: typePol,
      );

      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final int polygonId = await dbHelper.insertPolygone(newPolygone);

      // Enregistrer l'action de création
      await dbHelper.insertActionLog(
        ActionLog(
          polygoneId: polygonId,
          zoneId: zoneId,
          utilisateurId: userId,
          action: 'creation',
          details: jsonEncode({
            'type_pol': typePol,
            'nombre_points': points.length,
          }),
          dateAction: DateTime.now(),
        ),
      );

      return newPolygone.copyWith(id: polygonId);
    } catch (e) {
      print('Erreur lors de la création du polygone: $e');
      return null;
    }
  }

  // Modification d'un polygone existant
  static Future<Polygone?> modifyPolygon({
    required int polygonId,
    required List<LatLng> newPoints,
    required int zoneId,
    required int userId,
  }) async {
    if (newPoints.length < 3) {
      throw Exception('Un polygone doit avoir au moins 3 points');
    }

    try {
      // Convertir les nouveaux points en WKT
      final String newGeom = Polygone.pointsToWKT(newPoints);

      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      return await db.transaction((txn) async {
        // Récupérer le polygone original
        final originalResult = await txn.query(
          DatabaseHelper.tablePolygons,
          where: 'id = ?',
          whereArgs: [polygonId],
        );

        if (originalResult.isEmpty) {
          throw Exception('Polygone non trouvé');
        }

        final originalPolygone = Polygone.fromMap(originalResult.first);

        // Mettre à jour le polygone
        final updatedPolygone = originalPolygone.copyWithNewPoints(newPoints);
        await txn.update(
          DatabaseHelper.tablePolygons,
          updatedPolygone.toMap(),
          where: 'id = ?',
          whereArgs: [polygonId],
        );

        // Enregistrer l'action de modification
        await dbHelper.insertActionLog(
          ActionLog(
            polygoneId: polygonId,
            zoneId: zoneId,
            utilisateurId: userId,
            action: 'modification',
            details: jsonEncode({
              'ancien_nombre_points': originalPolygone.points.length,
              'nouveau_nombre_points': newPoints.length,
            }),
            dateAction: DateTime.now(),
          ),
        );

        return updatedPolygone;
      });
    } catch (e) {
      print('Erreur lors de la modification du polygone: $e');
      return null;
    }
  }

  // Suppression d'un polygone
  static Future<bool> deletePolygon({
    required int polygonId,
    required int zoneId,
    required int userId,
  }) async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      return await db.transaction((txn) async {
        // Récupérer les informations du polygone avant suppression
        final polygonData = await txn.query(
          DatabaseHelper.tablePolygons,
          where: 'id = ?',
          whereArgs: [polygonId],
        );

        if (polygonData.isEmpty) {
          throw Exception('Polygone non trouvé');
        }

        final polygone = Polygone.fromMap(polygonData.first);

        // Enregistrer l'action de suppression
        await dbHelper.insertActionLog(
          ActionLog(
            polygoneId: polygonId,
            zoneId: zoneId,
            utilisateurId: userId,
            action: 'suppression',
            details: jsonEncode({
              'type_pol': polygone.typePol,
              'nombre_points': polygone.points.length,
            }),
            dateAction: DateTime.now(),
          ),
        );

        // Supprimer le polygone
        await txn.delete(
          DatabaseHelper.tablePolygons,
          where: 'id = ?',
          whereArgs: [polygonId],
        );

        return true;
      });
    } catch (e) {
      print('Erreur lors de la suppression du polygone: $e');
      return false;
    }
  }

  // Méthodes privées pour la fusion de polygones
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

  // Méthode utilitaire pour convertir une chaîne géométrique en points
  static List<LatLng> geometryFromString(String geom) {
    try {
      return Polygone.fromMap({'geom': geom}).points;
    } catch (e) {
      print('Erreur lors de la conversion de la géométrie: $e');
      return [];
    }
  }
}