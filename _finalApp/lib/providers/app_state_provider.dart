import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../funct/modif_polygone.dart';
import '../funct/polygon_operations.dart';
import '../models/user.dart';
import '../models/zone.dart';
import '../models/polygone.dart';
import '../services/database_helper.dart';
import 'package:latlong2/latlong.dart';


class AppStateProvider with ChangeNotifier {
  User? _currentUser;
  Zone? _currentZone;
  List<Zone> _zones = [];
  List<Polygone> _polygons = [];
  List<Polygone> _selectedPolygons = [];

  // Getters
  User? get currentUser => _currentUser;
  Zone? get currentZone => _currentZone;
  List<Zone> get zones => _zones;
  List<Polygone> get polygons => _polygons;
  List<Polygone> get selectedPolygons => _selectedPolygons;

  // Vérification de l'état de base
  bool _checkUserAndZone() {
    if (_currentUser == null || _currentUser!.id == null || _currentZone == null) {
      print('Utilisateur ou zone non sélectionné');
      return false;
    }
    return true;
  }

  // Authentification
  Future<bool> login(String username, String password) async {
    try {
      final user = await DatabaseHelper.instance.getUser(username, password);
      if (user != null) {
        _currentUser = user;
        await loadZones();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur de connexion : $e');
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _currentZone = null;
    _zones = [];
    _polygons = [];
    _selectedPolygons.clear();
    notifyListeners();
  }

  // Gestion des zones
  Future<void> loadZones() async {
    if (_currentUser != null) {
      _zones = await DatabaseHelper.instance.getZonesByUser(_currentUser!.id!);
      notifyListeners();
    }
  }

  void setCurrentZone(Zone zone) {
    _currentZone = zone;
    loadPolygons();
    notifyListeners();
  }

  Future<void> loadPolygons() async {
    if (_currentZone != null) {
      _polygons = await DatabaseHelper.instance.getPolygonsByZone(_currentZone!.id);
      notifyListeners();
    }
  }

  // Gestion des polygones sélectionnés
  void selectPolygon(Polygone polygon) {
    if (!_selectedPolygons.contains(polygon)) {
      _selectedPolygons.add(polygon);
      notifyListeners();
    }
  }

  void unselectPolygon(Polygone polygon) {
    _selectedPolygons.remove(polygon);
    notifyListeners();
  }

  void clearSelection() {
    _selectedPolygons.clear();
    notifyListeners();
  }

  // Opérations sur les polygones
  Future<void> createPolygon(List<LatLng> points) async {
    if (!_checkUserAndZone()) return;

    try {
      final newPolygon = await PolygonOperations.createPolygon(
        points: points,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!,
      );

      if (newPolygon != null) {
        _polygons.add(newPolygon);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la création du polygone: $e');
    }
  }

  Future<void> deletePolygon() async {
    if (_selectedPolygons.isEmpty || !_checkUserAndZone()) return;

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

  Future<void> mergeSelectedPolygons() async {
    if (_selectedPolygons.length < 2 || !_checkUserAndZone()) return;

    try {
      final polygonIds = _selectedPolygons.map((p) => p.id).toList();

      final success = await PolygonOperations.mergePolygons(
        polygonIds: polygonIds,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!,
      );

      if (success) {
        await loadPolygons();
        _selectedPolygons.clear();
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la fusion des polygones: $e');
    }
  }

  // Nouvelle méthode pour ouvrir le dialogue d'édition
  Future<void> showPolygonEditor(BuildContext context, Polygone polygon) async {
    if (!_checkUserAndZone()) return;

    final List<LatLng>? modifiedPoints = await showDialog<List<LatLng>>(
      context: context,
      builder: (context) => PolygonEditorDialog(
        polygonId: polygon.id,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!,
        initialPoints: polygon.points,
        onPolygonModified: (points) async {
          await loadPolygons(); // Recharger les polygones après modification
        },
      ),
    );

    if (modifiedPoints != null) {
      await loadPolygons(); // Recharger les polygones après fermeture du dialogue
    }
  }

  // Méthode modifyPolygon simplifiée car la logique est maintenant dans PolygonEditorDialog
  Future<void> modifyPolygon(int polygonId, List<LatLng> newPoints) async {
    if (!_checkUserAndZone()) return;

    try {
      final success = await PolygonOperations.modifyPolygon(
        polygonId: polygonId,
        newPoints: newPoints,
        zoneId: _currentZone!.id,
        userId: _currentUser!.id!,
      );

      if (success) {
        await loadPolygons();
        notifyListeners();
      }
    } catch (e) {
      print('Erreur lors de la modification du polygone: $e');
    }
  }

  void transferBackupToAWS() {
    print("Transfert de la sauvegarde vers AWS...");
  }
}