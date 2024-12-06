import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:logging/logging.dart';
import 'funct/merge_polygone.dart';
import 'funct/modif_polygone.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

void main() {
  // mode debeug TODO: a suprimmer a la fin de l'application
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
// Ecran de la carte geojson
class GeoJsonMapScreen extends StatefulWidget {
  const GeoJsonMapScreen({super.key});

  @override
  GeoJsonMapScreenState createState() => GeoJsonMapScreenState();
}

class GeoJsonMapScreenState extends State<GeoJsonMapScreen> {
  //Logger pour enregistrer les messages de debogages
  final Logger _logger = Logger('GeoJsonMapScreenState');
  // MapPolygon est une classe qui represente un polygone sur la carte (id,liste points,bordure,ect

  final List<MapPolygon> _polygons = []; // liste des polygones affiche sur la map

  bool _isSelectionMode = false; // indique  si le mode de selection est active

  final List<MapPolygon> _selectedPolygons = [];//liste des polygones selectionne
  final MapController _mapController = MapController();
  // le controleur de la carte, package flutter_map

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
    //_loadGeoJson charge les donnes geojsondepuis un fichier et cree des polygones a partir des donnes
  }
// on ajoute les polygones a la liste _polygons
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
      _logger.severe('Erreur de chargement du  GeoJSON', e);
    }
  }
/// inverse le mode selection et clear la liste des polygones selectionnee
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedPolygons.clear();
    });
  }
/// la methode _selectPolygon() selectionne ou deselectionne un polygone si elle est deja presente
  void _selectPolygon(MapPolygon polygon) {
    setState(() {
      if (_selectedPolygons.contains(polygon)) {
        _selectedPolygons.remove(polygon);
      } else {
        _selectedPolygons.add(polygon);
      }
    });
  }
/// permet de merger une liste de polygones selectionne
  void _mergePolygons() {
    if (_selectedPolygons.length < 2) {
      Alert(
        context: context,
        title: "Operation impossible",
        desc: "Selectionnez au moins deux polygones",
        image: Image.asset("assets/icons/cancel.png",
          width: 100,
          height: 100,
        ),
          buttons: [
      DialogButton(
        child: Text( "Retour"),
          onPressed: () => Navigator.pop(context),
          color: const Color.fromRGBO(0, 179, 134, 1.0),
      )
        ]
      ).show();
      return;
    }

    // Transformer chaque polygone selectionnee en sa liste de points
    List<List<LatLng>> polygonsToMerge = _selectedPolygons.map((polygon) => polygon.points).toList();

    // appel de merge_polygone.dart pour le merge
    List<LatLng> mergedPoints = PolygonMerger.mergePolygons(polygonsToMerge);

    setState(() {
      // Maj de l'etat de la carte
      // Supression des polygones selectionnee de _polygons
      _polygons.removeWhere((p) => _selectedPolygons.contains(p));

      // add du new polygone merge
      _polygons.add(MapPolygon(
        id: _polygons.length , // trouver une alternative lorsque les id seront harmonise
        points: mergedPoints,
        color: Colors.green.withOpacity(0.3),
        borderColor: Colors.green,
        borderStrokeWidth: 3.0,
      ));

      // reset de la selection
      _selectedPolygons.clear();
      _isSelectionMode = false;
    });
  }
// editer un polygone selectionne
  void _editPolygon() {
    if (_selectedPolygons.length != 1) {
      Alert(
          context: context,
          title: "Operation impossible",
          desc: "Selectionnez un unique polygone !",
          image: Image.asset("assets/icons/cancel.png",
            width: 100,
            height: 100,
          ),
          buttons: [
            DialogButton(
              child: Text( "Retour"),
              onPressed: () => Navigator.pop(context),
              color: const Color.fromRGBO(0, 179, 134, 1.0),
            )
          ]
      ).show();
      return;
    }
// affichange de la boite de dialogue d'edition
    // showDialog() pour afficher une boite de dialogue
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
      // then est appelle lorsque showdialog est ferme
    ).then((editedPolygon) {
      if (editedPolygon != null) {
        setState(() {
          // retrouver l'indice du polygone qui a ete modifier
          int index = _polygons.indexWhere((p) => p.id == editedPolygon.id);
          if (index != -1) {
            _polygons[index] = editedPolygon;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(_isSelectionMode ? 'Selection de polygones' : 'SenMapEditor',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color:Colors.lightGreen,
          ),
        ),
        backgroundColor: Colors.white,
        actions: _isSelectionMode
            ? [
          IconButton(
            // si le mode de selection est active,alors les boutons actions seront affiche
            icon: const Icon(Icons.account_balance_wallet_outlined,
              size: 36,
              color: Colors.blue,

            ),
            onPressed: _mergePolygons,
            tooltip: 'Mode Fusion', // texte visible si appuie long
          ),
          IconButton(
            icon: const Icon(Icons.edit,
              size: 36,
              color: Colors.deepPurple,
            ),
            onPressed: _editPolygon,
            tooltip: 'Mode Edition',
          ),
        ]
            : [],
      ),
      body: Stack( // Stack, permet de superposer des widgets
        children: [
          FlutterMap(
            // _mapController est une instance de MapController fournis par fluttermap
            // permet de controler et interagir avec la carte
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.80046963, -17.24228481),
              initialZoom: 13.0,
              onTap: _isSelectionMode // si mode selection active
                  ? (tapPosition, point) {
                //tapPosition : position tape par l'user
                //point coordonnee du point tape

                // parcour _polygon pour verifier si un point est dans un des polygones
                for (var polygonData in _polygons) {
                  // la methode _isPointInPolygon definie en bas
                  if (_isPointInPolygon(point, polygonData.points)) {
                    _selectPolygon(polygonData);
                    //si le point est a l'interieur, alors le selectionner
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
                polygons: _polygons.map((polygonData) => polygonData.toPolygon()).toList(),
              ),

            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              // _toggleSelectionMode inverse le mode de selection
              onPressed: _toggleSelectionMode,
              backgroundColor: _isSelectionMode ? Colors.red : Colors.blue,
              child: Icon(_isSelectionMode ? Icons.close : Icons.tab_unselected,
                size: 30,),
            ),
          ),
        ],
      ),
    );
  }
// Pour determiner si un point est a l'interieur d'un polygone
// Algorithme de ray-casting
// voir https://xymaths.fr/MathAppli/Algorithme-Interieur-Polygone/
// Un point est a l'interieur sssi une demi droite passant par ce point coupant le polygone le coupe en un nombre impaire de poits
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
//  representation d'un polygone sur la carte
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

  // Convertir un objet MapPolygon en polygone au sens de flutter_map
  Polygon toPolygon() {
    return Polygon(
      points: points,
      color: color,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
    );
  }
}
