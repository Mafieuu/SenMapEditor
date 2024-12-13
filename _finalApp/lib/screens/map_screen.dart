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
  LatLng? _initialCenter;

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
        _initialCenter = _calculateInitialCenter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      _showErrorDialog('Erreur lors du chargement des données');
    }
  }

  LatLng _calculateInitialCenter() {
    if (_polygones.isEmpty) {
      // Centrage par défaut sur Sangalkam si pas de polygones
      // TODO: probleme pour centrer sur polygone
      return LatLng(14.79778, -17.24925);
    }

    // Prendre le premier point du premier polygone
    final firstPolygone = _polygones.first;
    final points = _parseGeometry(firstPolygone.geom);

    if (points.isNotEmpty) {
      return points.first;
    }

    // Centrage par défaut sur Dakar si pas de points
    return LatLng(14.6937, -17.4441);
  }

  List<LatLng> _parseGeometry(String geomString) {
    try {
      // Vérifier différents formats de stockage
      if (geomString.contains('POLYGON')) {
        // Format WKT
        final cleanGeom = geomString
            .replaceAll('POLYGON((', '')
            .replaceAll('))', '');

        return cleanGeom.split(',').map((coord) {
          final parts = coord.trim().split(' ');
          return LatLng(
              double.parse(parts[1]), // latitude
              double.parse(parts[0])  // longitude
          );
        }).toList();
      } else {
        // Format JSON
        final List<dynamic> coordinates = jsonDecode(geomString);
        return coordinates.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();
      }
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
          // Utiliser le centre calculé
          initialCenter: _initialCenter ?? LatLng(14.6937, -17.4441),
          initialZoom: 18.0,
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