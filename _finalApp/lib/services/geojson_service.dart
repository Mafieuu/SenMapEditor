import 'dart:convert';

import 'package:flutter/services.dart';
// Idee pour le moment abandonnee

class GeoJsonService {
  const GeoJsonService._();
  static const instance = GeoJsonService._();

  Future<Map<String, dynamic>> loadGeoJson(String filePath) async {
    try {
      if (!filePath.endsWith('.geojson')) {
        throw FormatException('Le fichier doit être au format .geojson');
      }

      final String data = await rootBundle.loadString(filePath);
      final Map<String, dynamic> jsonData = jsonDecode(data);

      if (!_isValidGeoJson(jsonData)) {
        throw FormatException('Format GeoJSON invalide');
      }

      return jsonData;
    } catch (e) {
      throw Exception('Erreur lors du chargement du GeoJSON: $e');
    }
  }

  bool _isValidGeoJson(Map<String, dynamic> json) {
    return json.containsKey('type') && json.containsKey('features');
  }
}