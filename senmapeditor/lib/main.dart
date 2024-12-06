import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'funct/merge_polygone.dart';
import 'funct/modif_polygone.dart';

void main() {
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
  final List<MapPolygon> _polygons = [];
  final List<MapPolygon> _selectedPolygons = [];
  final MapController _mapController = MapController();

  bool _isSelectionMode = false;
  bool _creatingNewPolygon = false;
  List<LatLng> _newPolygonPoints = [];

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
              _polygons.add(MapPolygon(
                id: DateTime.now().millisecondsSinceEpoch,
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
      _logger.severe('Erreur de chargement du GeoJSON', e);
    }
  }

  void _startPolygonCreation() {
    setState(() {
      _isSelectionMode = true;
      _creatingNewPolygon = true;
      _newPolygonPoints.clear();
    });
  }

  void _finalizePolygonCreation() {
    if (_newPolygonPoints.length >= 3) {
      setState(() {
        _polygons.add(MapPolygon(
          id: DateTime.now().millisecondsSinceEpoch,
          points: List.from(_newPolygonPoints),
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 3.0,
        ));
        _creatingNewPolygon = false;
        _newPolygonPoints.clear();
        _isSelectionMode = false;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPolygons.clear();
      _creatingNewPolygon = false;
    });
  }

  void _selectPolygon(MapPolygon polygon) {
    setState(() {
      if (_selectedPolygons.contains(polygon)) {
        _selectedPolygons.remove(polygon);
      } else {
        _selectedPolygons.add(polygon);
      }
    });
  }

  void _mergePolygons() {
    if (_selectedPolygons.length < 2) {
      _showErrorAlert('Select at least two polygons to merge');
      return;
    }

    List<List<LatLng>> polygonsToMerge = _selectedPolygons.map((p) => p.points).toList();
    List<LatLng> mergedPoints = PolygonMerger.mergePolygons(polygonsToMerge);

    setState(() {
      _polygons.removeWhere((p) => _selectedPolygons.contains(p));
      _polygons.add(MapPolygon(
        id: DateTime.now().millisecondsSinceEpoch,
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
      _showErrorAlert('Select exactly one polygon to edit');
      return;
    }

    showDialog<MapPolygon>(
      context: context,
      builder: (BuildContext context) => PolygonEditorDialog(
        polygon: PolygonData(
          id: _selectedPolygons.first.id.toString(),
          points: _selectedPolygons.first.points,
          color: _selectedPolygons.first.color,
          borderColor: _selectedPolygons.first.borderColor,
          borderStrokeWidth: _selectedPolygons.first.borderStrokeWidth,
        ),
      ),
    ).then((editedPolygon) {
      if (editedPolygon != null) {
        setState(() {
          int index = _polygons.indexWhere((p) => p.id == editedPolygon.id);
          if (index != -1) {
            _polygons[index] = editedPolygon;
          }
          _selectedPolygons.clear();
        });
      }
    });
  }

  void _showErrorAlert(String message) {
    Alert(
      context: context,
      title: "Operation Impossible",
      desc: message,
      image: Image.asset("assets/icons/cancel.png", width: 100, height: 100),
      buttons: [
        DialogButton(
          child: const Text("Return"),
          onPressed: () => Navigator.pop(context),
          color: const Color.fromRGBO(0, 179, 134, 1.0),
        )
      ]
    ).show();
  }

  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
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

  Polygon _createPolygon(MapPolygon polygonData, bool isSelected) {
    return Polygon(
      points: polygonData.points,
      color: isSelected ? polygonData.color.withOpacity(0.5) : polygonData.color,
      borderColor: polygonData.borderColor,
      borderStrokeWidth: polygonData.borderStrokeWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? 'Selection de polygones' : 'SenMapEditor',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.lightGreen,
          ),
        ),
        backgroundColor: Colors.white,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 36, color: Colors.blue),
                  onPressed: _mergePolygons,
                  tooltip: 'Mode Fusion',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 36, color: Colors.deepPurple),
                  onPressed: _editPolygon,
                  tooltip: 'Mode Edition',
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 36, color: Colors.green),
                  onPressed: _startPolygonCreation,
                  tooltip: 'Créer un polygone',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'Mode Sélection',
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 36, color: Colors.green),
                  onPressed: _startPolygonCreation,
                  tooltip: 'Créer un polygone',
                ),
              ],
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
                      if (_creatingNewPolygon) {
                        setState(() {
                          _newPolygonPoints.add(point);
                          
                          if (_newPolygonPoints.length >= 3) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text('Créer un polygone'),
                                content: const Text('Voulez-vous finaliser ce polygone ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _finalizePolygonCreation();
                                    },
                                    child: const Text('Oui'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Continuer'),
                                  ),
                                ],
                              ),
                            );
                          }
                        });
                      } else {
                        for (var polygonData in _polygons) {
                          if (_isPointInsidePolygon(point, polygonData.points)) {
                            _selectPolygon(polygonData);
                            break;
                          }
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
                polygons: _polygons.map((polygonData) => 
                  _createPolygon(polygonData, _selectedPolygons.contains(polygonData))
                ).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: _toggleSelectionMode,
              backgroundColor: _isSelectionMode ? Colors.red : Colors.blue,
              child: Icon(_isSelectionMode ? Icons.close : Icons.tab_unselected, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class MapPolygon {
  final int id;
  final List<LatLng> points;
  final Color color;
  final Color borderColor;
  final double borderStrokeWidth;

  const MapPolygon({
    required this.id,
    required this.points,
    required this.color,
    required this.borderColor,
    required this.borderStrokeWidth,
  });

  Polygon toPolygon() {
    return Polygon(
      points: points,
      color: color,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
    );
  }
}