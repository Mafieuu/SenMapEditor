import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:kenpachi/funct/polygon_operations.dart';

class PolygonEditorDialog extends StatefulWidget {
  final int polygonId;
  final int zoneId;
  final int userId;
  final List<LatLng> initialPoints;
  final Color color;
  final Color borderColor;
  final double borderStrokeWidth;
  final Function(List<LatLng>)? onPolygonModified;

  const PolygonEditorDialog({
    super.key,
    required this.polygonId,
    required this.zoneId,
    required this.userId,
    required this.initialPoints,
    this.color = const Color(0xFF2196F3),
    this.borderColor = const Color(0xFF000000),
    this.borderStrokeWidth = 2.0,
    this.onPolygonModified,
  });

  @override
  State<PolygonEditorDialog> createState() => _PolygonEditorDialogState();
}

class _PolygonEditorDialogState extends State<PolygonEditorDialog> {
  late List<LatLng> _editablePoints;
  bool _isAddPointMode = false;
  bool _isDeletePointMode = false;
  bool _isMovePointMode = false;
  int? _selectedPointIndex;
  late MapController _mapController;
  bool _isModifying = false;

  @override
  void initState() {
    super.initState();
    _editablePoints = List.from(widget.initialPoints);
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _toggleAddPointMode() {
    setState(() {
      _isAddPointMode = !_isAddPointMode;
      _isDeletePointMode = false;
      _isMovePointMode = false;
      _selectedPointIndex = null;
    });
  }

  void _toggleDeletePointMode() {
    setState(() {
      _isDeletePointMode = !_isDeletePointMode;
      _isAddPointMode = false;
      _isMovePointMode = false;
      _selectedPointIndex = null;
    });
  }

  void _toggleMovePointMode() {
    setState(() {
      _isMovePointMode = !_isMovePointMode;
      _isAddPointMode = false;
      _isDeletePointMode = false;
      _selectedPointIndex = null;
    });
  }

  Future<void> _addPoint(LatLng point) async {
    if (!_isAddPointMode || _isModifying) return;

    setState(() {
      _isModifying = true;
    });

    try {
      List<LatLng> newPoints = List.from(_editablePoints)..add(point);
      List<LatLng> convexHull = _enforceConvexPolygon(newPoints);
      
      setState(() {
        _editablePoints = convexHull;
        _isModifying = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout du point: ${e.toString()}')),
        );
      }
      setState(() {
        _isModifying = false;
      });
    }
  }

  Future<void> _deletePoint(LatLng point) async {
    if (!_isDeletePointMode || _isModifying || _editablePoints.length <= 3) return;

    setState(() {
      _isModifying = true;
    });

    try {
      List<LatLng> newPoints = _editablePoints.where(
        (p) => _calculateDistance(p, point) >= 0.0001
      ).toList();

      if (newPoints.length < 3) {
        throw Exception('Le polygone doit avoir au moins 3 points');
      }

      List<LatLng> convexHull = _enforceConvexPolygon(newPoints);
      
      setState(() {
        _editablePoints = convexHull;
        _isModifying = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression du point: ${e.toString()}')),
        );
      }
      setState(() {
        _isModifying = false;
      });
    }
  }

  Future<void> _selectOrMovePoint(LatLng point) async {
    if (!_isMovePointMode || _isModifying) return;

    setState(() {
      _isModifying = true;
    });

    try {
      if (_selectedPointIndex == null) {
        // Sélection du point
        int? index = _findClosestPointIndex(point);
        if (index != null) {
          setState(() {
            _selectedPointIndex = index;
            _isModifying = false;
          });
        } else {
          throw Exception('Aucun point proche trouvé');
        }
      } else {
        // Déplacement du point
        List<LatLng> newPoints = List.from(_editablePoints);
        newPoints[_selectedPointIndex!] = point;
        List<LatLng> convexHull = _enforceConvexPolygon(newPoints);
        
        setState(() {
          _editablePoints = convexHull;
          _selectedPointIndex = null;
          _isModifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du déplacement: ${e.toString()}')),
        );
      }
      setState(() {
        _isModifying = false;
      });
    }
  }

  int? _findClosestPointIndex(LatLng point) {
    double minDistance = double.infinity;
    int? closestIndex;

    for (int i = 0; i < _editablePoints.length; i++) {
      double distance = _calculateDistance(_editablePoints[i], point);
      if (distance < minDistance && distance < 0.0005) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  List<LatLng> _enforceConvexPolygon(List<LatLng> points) {
    if (points.length < 3) {
      throw Exception('Un polygone doit avoir au moins 3 points');
    }

    // Tri des points
    List<LatLng> workingPoints = List.from(points);
    workingPoints.sort((a, b) {
      int lonCompare = a.longitude.compareTo(b.longitude);
      return lonCompare != 0 ? lonCompare : a.latitude.compareTo(b.latitude);
    });

    // Calcul de l'enveloppe convexe
    List<LatLng> hull = [];
    
    // Construction de la partie inférieure
    for (var point in workingPoints) {
      while (hull.length >= 2 && _crossProduct(hull[hull.length-2], hull.last, point) <= 0) {
        hull.removeLast();
      }
      hull.add(point);
    }

    // Construction de la partie supérieure
    int k = hull.length;
    for (int i = workingPoints.length - 2; i >= 0; i--) {
      while (hull.length >= k + 1 && _crossProduct(hull[hull.length-2], hull.last, workingPoints[i]) <= 0) {
        hull.removeLast();
      }
      hull.add(workingPoints[i]);
    }

    hull.removeLast(); // Enlever le dernier point qui est dupliqué

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
      return const LatLng(14.80046963, -17.24228481); // Centre par défaut
    }
    
    double lat = 0, lon = 0;
    for (var point in points) {
      lat += point.latitude;
      lon += point.longitude;
    }
    return LatLng(lat / points.length, lon / points.length);
  }

  Future<void> _savePolygon() async {
    if (_editablePoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le polygone doit avoir au moins 3 points')),
      );
      return;
    }

    try {
      final success = await PolygonOperations.modifyPolygon(
        polygonId: widget.polygonId,
        newPoints: _editablePoints,
        zoneId: widget.zoneId,
        userId: widget.userId,
      );

      if (success && mounted) {
        widget.onPolygonModified?.call(_editablePoints);
        Navigator.of(context).pop(_editablePoints);
      } else if (mounted) {
        throw Exception('Échec de la modification du polygone');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Tooltip(
                  message: 'Ajouter un point',
                  child: ElevatedButton(
                    onPressed: _isModifying ? null : _toggleAddPointMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAddPointMode ? Colors.green : null,
                    ),
                    child: const Icon(Icons.add_location),
                  ),
                ),
                Tooltip(
                  message: 'Supprimer un point',
                  child: ElevatedButton(
                    onPressed: _isModifying ? null : _toggleDeletePointMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDeletePointMode ? Colors.red : null,
                    ),
                    child: const Icon(Icons.remove_circle),
                  ),
                ),
                Tooltip(
                  message: 'Déplacer un point',
                  child: ElevatedButton(
                    onPressed: _isModifying ? null : _toggleMovePointMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMovePointMode ? Colors.orange : null,
                    ),
                    child: const Icon(Icons.open_with),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _calculatePolygonCenter(_editablePoints),
                      initialZoom: 13.0,
                      onTap: _isModifying ? null : (tapPosition, point) {
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
                            color: widget.color.withOpacity(0.3),
                            borderColor: widget.borderColor,
                            borderStrokeWidth: widget.borderStrokeWidth,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: _editablePoints.asMap().entries.map((entry) {
                          final isSelected = _selectedPointIndex == entry.key;
                          return Marker(
                            point: entry.value,
                            width: 15,
                            height: 15,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.yellow : Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (_isModifying)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isModifying ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isModifying ? null : _savePolygon,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}