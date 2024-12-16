import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/polygone.dart';
import '../models/action_log.dart';
import '../services/database_helper.dart';

class PolygonOperations {
  // Fusion de polygones
  // -----------------------------------------------------------------------------

  static Future<Polygone?> mergePolygons({
    required List<int> polygonIds,
    required int zoneId,
    required int userId,
  }) async {
    try {
      if (polygonIds.length < 2) {
        throw Exception('Il faut au moins 2 polygones pour effectuer une fusion');
      }

      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      return await db.transaction((txn) async {
        // 1. Récupérer tous les polygones à fusionner avec validation
        final List<List<LatLng>> polygonsToMerge = [];
        final List<Map<String, dynamic>> polygonData = [];

        for (int id in polygonIds) {
          final result = await txn.query(
            DatabaseHelper.tablePolygons,
            where: 'id = ? AND zone_id = ?',  // Vérifier aussi la zone_id
            whereArgs: [id, zoneId],
          );

          if (result.isEmpty) {
            throw Exception('Polygone $id non trouvé dans la zone $zoneId');
          }

          final polygone = Polygone.fromMap(result.first);
          final points = polygone.points;

          if (points.isEmpty) {
            throw Exception('Polygone $id invalide: pas de points');
          }

          polygonData.add(result.first);
          polygonsToMerge.add(points);
        }

        // 2. Effectuer la fusion avec validation
        final List<LatLng> mergedPoints = _mergePolygons(polygonsToMerge);
        if (mergedPoints.length < 3) {
          throw Exception('Le polygone fusionné doit avoir au moins 3 points');
        }

        // 3. Créer le nouveau polygone avec les points fusionnés
        final newGeom = Polygone.pointsToWKT(mergedPoints);
        final newPolygone = Polygone(
          id: 20000, //Une solution temporaire
          zoneId: zoneId,
          geom: newGeom,
          typePol: 'merged',
        );

        // 4. Insérer le nouveau polygone
        final int newPolygonId = await txn.insert(
          DatabaseHelper.tablePolygons,
          newPolygone.toMap(),
        );

        if (newPolygonId <= 0) {
          throw Exception('Échec de l\'insertion du nouveau polygone');
        }

        // 5. Enregistrer l'action de fusion
        final actionLog = ActionLog(
          polygoneId: newPolygonId,
          zoneId: zoneId,
          utilisateurId: userId,
          action: 'MERGE',
          details: jsonEncode({
            'source_polygons': polygonIds,
            'points_count': mergedPoints.length,
          }),
          dateAction: DateTime.now(),
        );

        await txn.insert(
          DatabaseHelper.tableAction_log,
          actionLog.toMap(),
        );

        // 6. Supprimer les anciens polygones
        final deletedCount = await txn.delete(
          DatabaseHelper.tablePolygons,
          where: 'id IN (${List.filled(polygonIds.length, '?').join(',')})',
          whereArgs: polygonIds,
        );

        if (deletedCount != polygonIds.length) {
          throw Exception('Tous les polygones n\'ont pas été supprimés');
        }

        // 7. Retourner le nouveau polygone avec son ID
        return newPolygone.copyWith(id: newPolygonId);
      });
    } catch (e) {
      print('Erreur lors de la fusion des polygones: $e');
      return null;
    }
  }

  // Création d'un nouveau polygone
  // -----------------------------------------------------------------------------

  static Future<Polygone?> createPolygon({
    required List<LatLng> points,
    required int zoneId,
    required int userId,
    String? typePol,
  }) async {
    try {
      // Validation des points
      if (points.length < 3) {
        throw Exception('Un polygone doit avoir au moins 3 points');
      }

      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      return await db.transaction((txn) async {
        //  Créer le polygone avec les points
        final newGeom = Polygone.pointsToWKT(points);
        final newPolygone = Polygone(
          id: 10000,  // --------------------une solution temporaire
          zoneId: zoneId,
          geom: newGeom,
          typePol: typePol ?? 'default',
        );

        //  Insérer le nouveau polygone
        final int newPolygonId = await txn.insert(
          DatabaseHelper.tablePolygons,
          newPolygone.toMap(),
        );

        if (newPolygonId <= 0) {
          throw Exception('Échec de l\'insertion du nouveau polygone');
        }

        //  Enregistrer l'action de création
        final actionLog = ActionLog(
          polygoneId: newPolygonId,
          zoneId: zoneId,
          utilisateurId: userId,
          action: 'CREATE',
          details: jsonEncode({
            'type_pol': typePol,
            'points_count': points.length,
          }),
          dateAction: DateTime.now(),
        );

        await txn.insert(
          DatabaseHelper.tableAction_log,
          actionLog.toMap(),
        );

        //  Retourner le nouveau polygone avec son ID
        return newPolygone.copyWith(id: newPolygonId);
      });
    } catch (e) {
      print('Erreur lors de la création du polygone: $e');
      return null;
    }
  }

  // Modification d'un polygone existant
  // -----------------------------------------------------------------------------

  static Future<Polygone?> modifyPolygon({
    required int polygonId,
    required List<LatLng> newPoints,
    required int zoneId,
    required int userId,
  }) async {
    try {
      // Validation des points
      if (newPoints.length < 3) {
        throw Exception('Un polygone doit avoir au moins 3 points');
      }

      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      return await db.transaction((txn) async {
        // 1. Vérifier l'existence du polygone et sa zone
        final result = await txn.query(
          DatabaseHelper.tablePolygons,
          where: 'id = ? AND zone_id = ?',
          whereArgs: [polygonId, zoneId],
        );

        if (result.isEmpty) {
          throw Exception('Polygone $polygonId non trouvé dans la zone $zoneId');
        }

        final originalPolygone = Polygone.fromMap(result.first);

        // 2. Mettre à jour le polygone avec les nouveaux points
        final newGeom = Polygone.pointsToWKT(newPoints);
        final updatedPolygone = originalPolygone.copyWith(geom: newGeom);

        final updateCount = await txn.update(
          DatabaseHelper.tablePolygons,
          updatedPolygone.toMap(),
          where: 'id = ? AND zone_id = ?',
          whereArgs: [polygonId, zoneId],
        );

        if (updateCount != 1) {
          throw Exception('Échec de la mise à jour du polygone');
        }

        // 3. Enregistrer l'action de modification
        final actionLog = ActionLog(
          polygoneId: polygonId,
          zoneId: zoneId,
          utilisateurId: userId,
          action: 'UPDATE',
          details: jsonEncode({
            'original_points_count': originalPolygone.points.length,
            'new_points_count': newPoints.length,
          }),
          dateAction: DateTime.now(),
        );

        await txn.insert(
          DatabaseHelper.tableAction_log,
          actionLog.toMap(),
        );

        return updatedPolygone;
      });
    } catch (e) {
      print('Erreur lors de la modification du polygone: $e');
      return null;
    }
  }

  // Suppression d'un polygone
  // -----------------------------------------------------------------------------

  static Future<bool> deletePolygon({
    required int polygonId,
    required int zoneId,
    required int userId,
  }) async {
    try {
      final DatabaseHelper dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      return await db.transaction((txn) async {
        //  Vérifier l'existence du polygone et sa zone
        final result = await txn.query(
          DatabaseHelper.tablePolygons,
          where: 'id = ? AND zone_id = ?',
          whereArgs: [polygonId, zoneId],
        );

        if (result.isEmpty) {
          throw Exception('Polygone $polygonId non trouvé dans la zone $zoneId');
        }

        final polygone = Polygone.fromMap(result.first);

        //  Enregistrer l'action de suppression
        final actionLog = ActionLog(
          polygoneId: polygonId,
          zoneId: zoneId,
          utilisateurId: userId,
          action: 'DELETE',
          details: jsonEncode({
            'type_pol': polygone.typePol,
            'points_count': polygone.points.length,
          }),
          dateAction: DateTime.now(),
        );

        await txn.insert(
          DatabaseHelper.tableAction_log,
          actionLog.toMap(),
        );

        //  Supprimer le polygone
        final deleteCount = await txn.delete(
          DatabaseHelper.tablePolygons,
          where: 'id = ? AND zone_id = ?',
          whereArgs: [polygonId, zoneId],
        );

        if (deleteCount != 1) {
          throw Exception('Échec de la suppression du polygone');
        }

        return true;
      });
    } catch (e) {
      print('Erreur lors de la suppression du polygone: $e');
      return false;
    }
  }
  // -----------------------------------------------------------------------------
  // -----------------------------------------------------------------------------
  // -----------------------------------------------------------------------------

  // definiton des methodes utulise
  static List<LatLng> _mergePolygons(List<List<LatLng>> polygons) {
    if (polygons.isEmpty) return [];
    if (polygons.length == 1) return polygons.first;

    // Combiner tous les points des polygones
    List<LatLng> allPoints = [];
    for (var polygon in polygons) {
      allPoints.addAll(polygon);
    }

    // Éliminer les points trop proches
    List<LatLng> uniquePoints = [];
    for (var point in allPoints) {
      bool shouldAdd = true;
      for (var existing in uniquePoints) {
        if (_arePointsClose(point, existing)) {
          shouldAdd = false;
          break;
        }
      }
      if (shouldAdd) {
        uniquePoints.add(point);
      }
    }

    // Calculer l'enveloppe convexe
    return _convexHull(uniquePoints);
  }

  static List<LatLng> _convexHull(List<LatLng> points) {
    if (points.length < 3) return points;

    // Trouver le point le plus bas
    LatLng start = points.reduce((curr, next) =>
    curr.latitude < next.latitude ? curr : next);

    List<LatLng> hull = [];
    LatLng endpoint;
    LatLng currentPoint = start;

    do {
      hull.add(currentPoint);
      endpoint = points[0];

      for (int i = 1; i < points.length; i++) {
        if ((endpoint == currentPoint) ||
            _crossProduct(currentPoint, endpoint, points[i]) < 0) {
          endpoint = points[i];
        }
      }

      currentPoint = endpoint;
    } while (endpoint != start);

    return hull;
  }

  static bool _arePointsClose(LatLng p1, LatLng p2, {double threshold = 1e-6}) {
    return _calculateDistance(p1, p2) < threshold;
  }

  static double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // Rayon moyen de la Terre en mètres

    double lat1 = p1.latitude * pi / 180;
    double lat2 = p2.latitude * pi / 180;
    double dLat = (p2.latitude - p1.latitude) * pi / 180;
    double dLon = (p2.longitude - p1.longitude) * pi / 180;

    double a = sin(dLat/2) * sin(dLat/2) +
        cos(lat1) * cos(lat2) *
            sin(dLon/2) * sin(dLon/2);

    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return earthRadius * c;
  }

  static double _crossProduct(LatLng o, LatLng a, LatLng b) {
    return (a.longitude - o.longitude) * (b.latitude - o.latitude) -
        (a.latitude - o.latitude) * (b.longitude - o.longitude);
  }
}