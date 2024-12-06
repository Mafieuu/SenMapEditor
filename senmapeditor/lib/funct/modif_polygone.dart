import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geojsonmaj/main.dart';
import 'package:latlong2/latlong.dart';

// Définition de la classe PolygonData
class PolygonData {
  final String id;
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

  // Ajout d'une méthode de copie pour faciliter les modifications
  PolygonData copyWith({
    String? id,
    List<LatLng>? points,
    Color? color,
    Color? borderColor,
    double? borderStrokeWidth,
  }) {
    return PolygonData(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderStrokeWidth: borderStrokeWidth ?? this.borderStrokeWidth,
    );
  }
}

class PolygonEditorDialog extends StatefulWidget {
  final PolygonData polygon;

  const PolygonEditorDialog({super.key, required this.polygon});

  @override
  State<PolygonEditorDialog> createState() => _PolygonEditorDialogState();
}

class _PolygonEditorDialogState extends State<PolygonEditorDialog> {
  late List<LatLng> _editablePoints;
  bool _isAddPointMode = false;
  bool _isDeletePointMode = false;
  bool _isMovePointMode = false;
  int? _selectedPointIndex;
  MapController? _mapController;

  @override
  void initState() {
    super.initState();
    _editablePoints = List.from(widget.polygon.points);
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _toggleAddPointMode() {
    if (!mounted) return;
    setState(() {
      _isAddPointMode = !_isAddPointMode;
      _isDeletePointMode = false;
      _isMovePointMode = false;
    });
  }

  void _toggleDeletePointMode() {
    if (!mounted) return;
    setState(() {
      _isDeletePointMode = !_isDeletePointMode;
      _isAddPointMode = false;
      _isMovePointMode = false;
    });
  }

  void _toggleMovePointMode() {
    if (!mounted) return;
    setState(() {
      _isMovePointMode = !_isMovePointMode;
      _isAddPointMode = false;
      _isDeletePointMode = false;
      _selectedPointIndex = null;
    });
  }

  void _addPoint(LatLng point) {
    if (!_isAddPointMode || !mounted) return;

    setState(() {
      _editablePoints.add(point);
      try {
        _editablePoints = _enforceConvexPolygon(_editablePoints);
      } catch (e) {
        debugPrint('Erreur lors de l\'application de la convexité: $e');
      }
    });
  }

  void _deletePoint(LatLng point) {
    if (!_isDeletePointMode || !mounted || _editablePoints.length <= 3) return;

    setState(() {
      _editablePoints.removeWhere(
              (p) => _calculateDistance(p, point) < 0.0001
      );

      if (_editablePoints.length < 3) {
        _editablePoints = List.from(widget.polygon.points);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le polygone doit avoir au moins 3 points'),
          ),
        );
      } else {
        try {
          _editablePoints = _enforceConvexPolygon(_editablePoints);
        } catch (e) {
          debugPrint('Erreur lors de l\'application de la convexité: $e');
          _editablePoints = List.from(widget.polygon.points);
        }
      }
    });
  }

void _selectOrMovePoint(LatLng point) {
  if (!_isMovePointMode || !mounted) return;

  const double minDistance = 0.0005;
  int? closestIndex;

  for (int i = 0; i < _editablePoints.length; i++) {
    double distance = _calculateDistance(_editablePoints[i], point);
    if (distance < minDistance) {
      closestIndex = i;
      break;
    }
  }

  setState(() {
    if (_selectedPointIndex == null) {
      if (closestIndex != null) {
        _selectedPointIndex = closestIndex;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Point sélectionné. Appuyez maintenant pour le déplacer.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (closestIndex != null) {
      final previousPoints = List<LatLng>.from(_editablePoints);

      _editablePoints[_selectedPointIndex!] = point;
      _selectedPointIndex = null;

      try {
        _editablePoints = _enforceConvexPolygon(_editablePoints);
      } catch (e) {
        debugPrint('Erreur lors du déplacement du point: $e');
        _editablePoints = previousPoints;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de déplacer le point à cette position'),
          ),
        );
      }
    }
  });
}

  List<LatLng> _enforceConvexPolygon(List<LatLng> points) {
    if (points.length < 3) {
      throw Exception('Un polygone doit avoir au moins 3 points');
    }

    List<LatLng> workingPoints = List.from(points);

    workingPoints.sort((a, b) {
      int lonCompare = a.longitude.compareTo(b.longitude);
      return lonCompare != 0 ? lonCompare : a.latitude.compareTo(b.latitude);
    });

    List<LatLng> hull = [];

    for (var point in workingPoints) {
      while (hull.length >= 2 && _crossProduct(hull[hull.length-2], hull.last, point) <= 0) {
        hull.removeLast();
      }
      hull.add(point);
    }

    int k = hull.length;
    for (int i = workingPoints.length - 2; i >= 0; i--) {
      while (hull.length >= k + 1 && _crossProduct(hull[hull.length-2], hull.last, workingPoints[i]) <= 0) {
        hull.removeLast();
      }
      hull.add(workingPoints[i]);
    }

    hull.removeLast();

    if (hull.length < 3) {
      throw Exception('Impossible de créer un polygone convexe avec ces points');
    }

    return hull;
  }

  double _crossProduct(LatLng o, LatLng a, LatLng b) {
    return (a.longitude - o.longitude) * (b.latitude - o.latitude) -
        (a.latitude - o.latitude) * (b.longitude - o.longitude);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return const Distance().distance(point1, point2);
  }

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    if (points.isEmpty) {
      return const LatLng(14.80046963, -17.24228481);
    }
    double lat = 0, lon = 0;
    for (var point in points) {
      lat += point.latitude;
      lon += point.longitude;
    }
    return LatLng(lat / points.length, lon / points.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_editablePoints.isEmpty) {
      return const AlertDialog(
        title: Text('Erreur'),
        content: Text('Impossible de charger le polygone'),
      );
    }

    return AlertDialog(
      title: const Text('Éditeur de polygone'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _toggleAddPointMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAddPointMode ? Colors.green : null,
                  ),
                  child: const Icon(Icons.add),
                ),
                ElevatedButton(
                  onPressed: _toggleDeletePointMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDeletePointMode ? Colors.red : null,
                  ),
                  child: const Icon(Icons.delete),
                ),
                ElevatedButton(
                  onPressed: _toggleMovePointMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMovePointMode ? Colors.orange : null,
                  ),
                  child: const Icon(Icons.moving),
                ),
              ],
            ),
            if (_mapController != null) Expanded(
              child: FlutterMap(
                mapController: _mapController!,
                options: MapOptions(
                  initialCenter: _calculatePolygonCenter(_editablePoints),
                  initialZoom: 13.0,
                  onTap: (tapPosition, point) {
                    if (_isAddPointMode) {
                      _addPoint(point);
                    } else if (_isDeletePointMode) {
                      _deletePoint(point);
                    } else if (_isMovePointMode) {
                      _selectOrMovePoint(point);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _editablePoints,
                        color: widget.polygon.color.withOpacity(0.3),
                        borderColor: widget.polygon.borderColor,
                        borderStrokeWidth: widget.polygon.borderStrokeWidth,
                      )
                    ],
                  ),
                  MarkerLayer(
                    markers: _editablePoints.asMap().entries.map((entry) {
                      return Marker(
                        point: entry.value,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedPointIndex == entry.key
                                ? Colors.yellow
                                : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white,
                                width: 2
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
  TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const Text('Annuler'),
  ),
  TextButton(
    onPressed: () {
      if (_editablePoints.length >= 3) {
        // Convert _editablePoints back to a MapPolygon
        MapPolygon updatedPolygon = MapPolygon(
          id: int.parse(widget.polygon.id),
          points: _editablePoints,
          color: widget.polygon.color,
          borderColor: widget.polygon.borderColor,
          borderStrokeWidth: widget.polygon.borderStrokeWidth,
        );
        Navigator.of(context).pop(updatedPolygon);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le polygone doit avoir au moins 3 points'),
          ),
        );
      }
    },
    child: const Text('Valider'),
  ),
],

    );
  }
}