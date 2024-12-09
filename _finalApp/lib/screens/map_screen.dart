import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/zone.dart';
import 'dart:convert';
import '../models/polygone.dart';
import '../services/database_helper.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_dialog.dart';

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

  Future<void> _loadPolygonsFromDatabase() async {
    if (!mounted) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final Zone? currentZone = appState.currentZone;

    if (currentZone == null) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      // Charger les polygones depuis SQLite
      final polygones = await DatabaseHelper.instance.getPolygonsByZone(currentZone.id);

      if (!mounted) return;

      setState(() {
        _polygones = polygones;
        _isLoading = false;
      });

      // Centrer la carte sur le premier polygone si disponible
      if (_polygones.isNotEmpty) {
        _centerMapOnPolygones();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      _showErrorDialog('Erreur lors du chargement des données');
    }
  }

  void _centerMapOnPolygones() {
    if (_polygones.isEmpty) return;

    // Calculer le centre des polygones
    double sumLat = 0;
    double sumLng = 0;
    int pointCount = 0;

    for (var polygone in _polygones) {
      // Convertir la géométrie stockée en points
      final List<dynamic> points = _parseGeometry(polygone.geom);
      for (var point in points) {
        sumLat += point.latitude;
        sumLng += point.longitude;
        pointCount++;
      }
    }

    if (pointCount > 0) {
      final center = LatLng(sumLat / pointCount, sumLng / pointCount);
      _mapController.move(center, 13.0);
    }
  }

  List<LatLng> _parseGeometry(String geomString) {
    // Convertir la chaîne de géométrie en liste de points
    try {
      final List<dynamic> coordinates = jsonDecode(geomString);
      return coordinates.map((coord) {
        return LatLng(coord[1] as double, coord[0] as double);
      }).toList();
    } catch (e) {
      print('Erreur lors du parsing de la géométrie: $e');
      return [];
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carte')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erreur lors du chargement des données'),
              ElevatedButton(
                onPressed: _loadPolygonsFromDatabase,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(Provider.of<AppStateProvider>(context).currentZone?.nom ?? 'Carte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPolygonsFromDatabase,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(14.6937, -17.4441), // Coordonnées par défaut (Dakar)
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          PolygonLayer(
            polygons: _polygones.map((polygone) {
              return Polygon(
                points: _parseGeometry(polygone.geom),
                color: Colors.blue.withOpacity(0.3),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}