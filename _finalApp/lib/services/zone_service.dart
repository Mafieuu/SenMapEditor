import 'dart:async';

import 'package:kenpachi/models/zone.dart';

import 'database_helper.dart';

class ZoneService {
  const ZoneService._();
  static const instance = ZoneService._();

  Future<List<Zone>> getZonesByUser(int userId) async {
    if (userId <= 0) {
      throw ArgumentError('ID utilisateur invalide');
    }

    try {
      final zones = await DatabaseHelper.instance.getZonesByUser(userId);
      return zones..sort((a, b) => a.nom.compareTo(b.nom)); // Tri par nom
    } catch (e) {
      throw Exception('Erreur lors de la récupération des zones: $e');
    }
  }

  Future<Zone?> getZoneById(int zoneId) async {
    try {
      return await DatabaseHelper.instance.getZoneById(zoneId);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la zone: $e');
    }
  }
}