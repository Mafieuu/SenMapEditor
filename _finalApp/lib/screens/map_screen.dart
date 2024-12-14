import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/polygone.dart';
import '../providers/app_state_provider.dart';
import '../services/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  bool _isError = false;
  List<Polygone> _polygones = [];
  LatLng? _initialCenter;
  bool _isDrawingMode = false;
  bool _isSelectionMode = false;
  List<LatLng> _drawingPoints = [];

  @override
  void initState() {
    super.initState();
    _loadPolygonsFromDatabase();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Chargement des polygones
  Future<void> _loadPolygonsFromDatabase() async {
    if (!mounted) return;
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final currentZone = appState.currentZone;

    if (currentZone == null) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final polygones = await DatabaseHelper.instance.getPolygonsByZone(currentZone.id);
      if (!mounted) return;
      setState(() {
        _polygones = polygones;
        _initialCenter = _calculateInitialCenter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      _showErrorDialog('Erreur lors du chargement des données: $e');
    }
  }

  // Nouvelle méthode pour gérer la sélection des polygones
  void _handlePolygonTap(Polygone polygon) {
    if (!_isDrawingMode && _isSelectionMode) {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      if (appState.selectedPolygons.contains(polygon)) {
        appState.unselectPolygon(polygon);
      } else {
        appState.selectPolygon(polygon);
      }
    }
  }

  // Méthode modifiée pour gérer les taps sur la carte
  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawingMode) {
      setState(() {
        _drawingPoints.add(point);
      });
    } else if (_isSelectionMode) {
      // Vérifier si le tap est sur un polygone
      for (var polygon in _polygones) {
        if (_isPointInPolygon(point, polygon.points)) {
          _handlePolygonTap(polygon);
          break;
        }
      }
    }
  }

  // Méthode pour vérifier si un point est dans un polygone
  bool _isPointInPolygon(LatLng point, List<LatLng> polygonPoints) {
    bool inside = false;
    int j = polygonPoints.length - 1;

    for (int i = 0; i < polygonPoints.length; i++) {
      if ((polygonPoints[i].latitude > point.latitude) !=
          (polygonPoints[j].latitude > point.latitude) &&
          point.longitude < (polygonPoints[j].longitude - polygonPoints[i].longitude) *
              (point.latitude - polygonPoints[i].latitude) /
              (polygonPoints[j].latitude - polygonPoints[i].latitude) +
              polygonPoints[i].longitude) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appState.currentZone?.nom ?? 'Carte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPolygonsFromDatabase,
          ),
          // Nouveau bouton pour le mode sélection
          IconButton(
            icon: Icon(
              Icons.select_all,
              color: _isSelectionMode ? Colors.blue : null,
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  appState.clearSelection();
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter ?? const LatLng(14.6937, -17.4441),
              initialZoom: 18.0,
              onTap: _handleMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolygonLayer(
                polygons: [
                  ..._polygones.map((polygone) {
                    final isSelected = appState.selectedPolygons.contains(polygone);
                    return Polygon(
                      points: polygone.points,
                      color: isSelected
                          ? Colors.red.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.3),
                      borderColor: isSelected ? Colors.red : Colors.blue,
                      borderStrokeWidth: isSelected ? 3 : 2,
                      isDotted: isSelected,
                    );
                  }),
                  if (_isDrawingMode && _drawingPoints.length >= 2)
                    Polygon(
                      points: _drawingPoints,
                      color: Colors.green.withOpacity(0.3),
                      borderColor: Colors.green,
                      borderStrokeWidth: 2,
                      isDotted: true,
                    ),
                ],
              ),
            ],
          ),
          if (_isDrawingMode)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Mode dessin actif - Touchez la carte pour ajouter des points',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (_isSelectionMode)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Mode sélection actif - Touchez les polygones pour les sélectionner',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (!_isDrawingMode) ...[
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Créer un polygone',
                  onPressed: () {
                    setState(() {
                      _isDrawingMode = true;
                      _isSelectionMode = false;
                      appState.clearSelection();
                    });
                  },
                ),
                if (appState.selectedPolygons.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Modifier',
                    onPressed: appState.selectedPolygons.length == 1
                        ? () => appState.showPolygonEditor(
                      context,
                      appState.selectedPolygons.first,
                    )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Supprimer',
                    onPressed: () async {
                      await appState.deletePolygon();
                      await _loadPolygonsFromDatabase();
                    },
                  ),
                  if (appState.selectedPolygons.length >= 2)
                    IconButton(
                      icon: const Icon(Icons.merge),
                      tooltip: 'Fusionner',
                      onPressed: () async {
                        final success = await appState.mergeSelectedPolygons();
                        if (success) {
                          // Reload polygons to ensure UI is updated
                          await _loadPolygonsFromDatabase();

                          // Show a success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Polygones fusionnés avec succès')),
                          );
                        } else {
                          // Show an error message if merge failed
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erreur lors de la fusion des polygones'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                ],
                IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Sauvegarder',
                  onPressed: _saveToDatabase,
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  tooltip: 'Synchroniser avec AWS',
                  onPressed: () {
                    appState.transferBackupToAWS();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Synchronisation avec AWS en cours...'),
                      ),
                    );
                  },
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Terminer le dessin',
                  onPressed: () async {
                    await _finishDrawing();
                    await _loadPolygonsFromDatabase();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Annuler dernier point',
                  onPressed: _drawingPoints.isNotEmpty
                      ? () {
                    setState(() {
                      _drawingPoints.removeLast();
                    });
                  }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Annuler le dessin',
                  onPressed: _cancelDrawing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires conservées de votre code original
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  LatLng _calculateInitialCenter() {
    if (_polygones.isEmpty) {
      return const LatLng(14.79778, -17.24925);
    }
    try {
      return _polygones.first.calculateCenter();
    } catch (e) {
      return const LatLng(14.6937, -17.4441);
    }
  }

  Future<void> _saveToDatabase() async {
    try {
      await DatabaseHelper.instance.savePolygons(_polygones);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sauvegarde effectuée')),
      );
    } catch (e) {
      _showErrorDialog('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> _finishDrawing() async {
    if (_drawingPoints.length < 3) {
      _showErrorDialog('Un polygone doit avoir au moins 3 points');
      return;
    }

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.createPolygon(_drawingPoints);
      setState(() {
        _isDrawingMode = false;
        _drawingPoints.clear();
      });
    } catch (e) {
      _showErrorDialog('Erreur lors de la création du polygone: $e');
    }
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawingMode = false;
      _drawingPoints.clear();
    });
  }
}