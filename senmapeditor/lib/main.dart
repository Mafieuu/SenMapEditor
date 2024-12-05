import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';

void main() {
  // Pour le debeging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SenMapEditor- ENSAE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
     
      home: const GeoJsonMapScreen(),
    );
  }
}

class GeoJsonMapScreen extends StatefulWidget {
  const GeoJsonMapScreen({super.key});

  @override
  GeoJsonMapScreenState createState() => GeoJsonMapScreenState();
}

class GeoJsonMapScreenState extends State<GeoJsonMapScreen> {
  final Logger _logger = Logger('GeoJsonMapScreenState');
  final List<PolygonData> _polygons = [];
  bool _isSelectionMode = false;
  final List<PolygonData> _selectedPolygons = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      final String data = await rootBundle.loadString('assets/data.geojson');
      final Map<String, dynamic> geoJson = jsonDecode(data);
      if (geoJson['features'] != null) {
        final List<dynamic> features = geoJson['features'];
        for (var feature in features) {
          if (feature['geometry']['type'] == 'Polygon') {
            final List<dynamic> coordinates = feature['geometry']['coordinates'][0];
            final polygonPoints = coordinates
                .map((point) => LatLng(point[1], point[0]))
                .toList();
            setState(() {
              _polygons.add(PolygonData(
                id: _polygons.length,
                points: polygonPoints,
                color: Colors.blue.withOpacity(0.3),
                borderColor: Colors.blue,
                borderStrokeWidth: 3.0,
              ));
            });
          }
        }
      }
    } catch (e) {
      _logger.severe('Error loading GeoJSON', e);
    }
  }
// active ou désactive le mode de sélection des polygones

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPolygons.clear();
    });
  }
// ajouter ou retirer (si plusieurs selection) un polygone de la liste

  void _selectPolygon(PolygonData polygon) {
    setState(() {
      if (_selectedPolygons.contains(polygon)) {
        _selectedPolygons.remove(polygon);
      } else {
        _selectedPolygons.add(polygon);
      }
    });
  }
// merge des polygones

  void _mergePolygons() {
    if (_selectedPolygons.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Au moins deux polygones pour la fusion')),
      );return;  // fin de la fonction 
    }

    // La strategie de fusion :combiner les points des polygones,
    // delete des points doublons
    
    // Si la fusion fait un truc bizare alors Modifier le point
    List<LatLng> mergedPoints = [];
    for (var polygon in _selectedPolygons) {
      mergedPoints.addAll(polygon.points);
    }
    Set<LatLng> uniquePoints = mergedPoints.toSet();
    mergedPoints = uniquePoints.toList();

    
    setState(() {
      //supression des polygones fusionnee
      _polygons.removeWhere((p) => _selectedPolygons.contains(p));
      _polygons.add(PolygonData(
        id: _polygons.length, // plustard on uniformise les id
        points: mergedPoints,
        color: Colors.green.withOpacity(0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 3.0,
      ));
      _selectedPolygons.clear();
      _isSelectionMode = false;
    });
  }

  void _editPolygon() {
    if (_selectedPolygons.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select exactly one polygon to edit')),
      );
      return;
    }

    // modification du polygone
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Polygon'),
        content: const Text('Bientot disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Selection de polygones' : 'SenMapEditor'),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.merge_type),
                  onPressed: _mergePolygons,
                  tooltip: 'Merge Polygons',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editPolygon,
                  tooltip: 'Edit Polygon',
                ),
              ]
            : [],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.80046963, -17.24228481),
              initialZoom: 13.0,
              onTap: _isSelectionMode 
                ? (tapPosition, point) {
                    // Find the polygon that was tapped
                    for (var polygonData in _polygons) {
                      if (_isPointInPolygon(point, polygonData.points)) {
                        _selectPolygon(polygonData);
                        break;
                      }
                    }
                  }
                : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              PolygonLayer(
                polygons: _polygons.map((polygonData) {
                  return Polygon(
                    points: polygonData.points,
                    color: _selectedPolygons.contains(polygonData)
                        ? Colors.red.withOpacity(0.5)
                        : polygonData.color,
                    borderColor: _selectedPolygons.contains(polygonData)
                        ? Colors.red
                        : polygonData.borderColor,
                    borderStrokeWidth: polygonData.borderStrokeWidth,
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: _toggleSelectionMode,
              backgroundColor: _isSelectionMode ? Colors.red : Colors.blue,
              child: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            ),
          ),
        ],
      ),
    );
  }

  // algorithme du ray casting pour determiner si un point est a l'interieur d'un polygone
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * 
           (point.latitude - polygon[i].latitude) / 
           (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        inside = !inside;
      }
    }
    return inside;
  }
}

class PolygonData {
  final int id;
  final List<LatLng> points;
  final Color color;
  final Color borderColor;
  final double borderStrokeWidth;

  const PolygonData({
    required this.id,
    required this.points,
    required this.color,
    required this.borderColor,
    required this.borderStrokeWidth,
  });
}