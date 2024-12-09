import 'package:flutter/material.dart';
import '../funct/polygon_operations.dart';
import '../models/user.dart';
import '../models/zone.dart';
import '../models/polygone.dart';
import '../services/database_helper.dart';
import 'package:latlong2/latlong.dart';

class AppStateProvider extends ChangeNotifier {
  User? _currentUser;
  Zone? _currentZone;
  List<Zone> _zones = [];
  List<Polygone> _polygons = [];
  List<Polygone> _selectedPolygons = [];

  User? get currentUser => _currentUser;
  Zone? get currentZone => _currentZone;
  List<Zone> get zones => _zones;
  List<Polygone> get polygons => _polygons;
  List<Polygone> get selectedPolygons => _selectedPolygons;

  /// Authentifie l'utilisateur avec le nom et le mot de passe fournis.
  Future<bool> login(String nom, String paswd) async {
    final user = await DatabaseHelper.instance.getUser(nom, paswd);


    // TODO: delete les astuces de debogages
  print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx resultat de getUser");
    print('Résultat de getUser : $user');
    if (user != null) {
      _currentUser = user;
      await loadZones(); // Charger automatiquement les zones après la connexion
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Déconnecte l'utilisateur actuel et sauvegarde les changements dans la base de données.
  Future<void> logout() async {
    await _saveChanges();
    _currentUser = null;
    _currentZone = null;
    _zones = [];
    _polygons = [];
    _selectedPolygons.clear();
    notifyListeners();
  }

  /// Sauvegarde les changements dans la base de données.
  Future<void> _saveChanges() async {
    for (var polygon in _polygons) {
      await DatabaseHelper.instance.insertPolygone(polygon);
    }
  }

  /// Charge les zones associées à l'utilisateur actuel.
  Future<void> loadZones() async {
    var _currentUser = this._currentUser;
    if (_currentUser != null) {
      _zones = await DatabaseHelper.instance.getZonesByUser(_currentUser!.id!);
      notifyListeners();
    }
  }

  /// Définit la zone actuelle et charge ses polygones.
  void setCurrentZone(Zone zone) {
    _currentZone = zone;
    loadPolygons(); // Charger automatiquement les polygones de la zone
    notifyListeners();
  }

  /// Charge les polygones associés à la zone actuelle.
  Future<void> loadPolygons() async {
    if (_currentZone != null) {
      _polygons = await DatabaseHelper.instance.getPolygonsByZone(_currentZone!.id);
      notifyListeners();
    }
  }

  /// Crée un nouveau polygone.
  Future<void> createPolygon(List<LatLng> points) async {
    if (_currentUser == null || _currentUser!.id == null || _currentZone == null) {
      print('Utilisateur ou zone non sélectionné');
      return;
    }

    try {
      final newPolygon = await PolygonOperations.createPolygon(
        points: points,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!, // Utilisez l'opérateur ! ici
      );

      if (newPolygon != null) {
        _polygons.add(newPolygon);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la création du polygone: $e');
    }
  }

  /// Supprime un polygone.
  Future<void> deletePolygon() async {
    if (_selectedPolygons.isEmpty || _currentUser == null || _currentZone == null) {
      return;
    }

    final polygonToDelete = _selectedPolygons.first;

    try {
      final success = await PolygonOperations.deletePolygon(
        polygonId: polygonToDelete.id,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!,
      );

      if (success) {
        _polygons.removeWhere((p) => p.id == polygonToDelete.id);
        _selectedPolygons.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la suppression du polygone: $e');
    }
  }

  /// Fusionne des polygones.
  Future<void> mergeSelectedPolygons() async {
    if (_selectedPolygons.length < 2 || _currentUser == null || _currentZone == null) {
      return;
    }

    try {
      final polygonIds = _selectedPolygons.map((p) => p.id).toList();

      final success = await PolygonOperations.mergePolygons(
        polygonIds: polygonIds,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!,
      );

      if (success) {
        await loadPolygons(); // Recharger les polygones après la fusion
        _selectedPolygons.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la fusion des polygones: $e');
    }
  }

  /// Modifie un polygone.
  Future<void> modifyPolygon(int polygonId, List<LatLng> newPoints) async {
    if (_currentUser == null || _currentZone == null) {
      return;
    }

    try {
      final success = await PolygonOperations.modifyPolygon(
        polygonId: polygonId,
        newPoints: newPoints,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!,
      );

      if (success) {
        await loadPolygons(); // Recharger les polygones pour refléter la modification
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la modification du polygone: $e');
    }
  }

  /// Transfère la sauvegarde de la base de données vers AWS (fonctionnalité fictive).
  void transferBackupToAWS() {
    print("Transfert de la sauvegarde vers AWS...");
  }
}