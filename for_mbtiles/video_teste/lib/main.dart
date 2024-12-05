import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sen_Map_Editor - ENSAE- '),
        ),
        body: FutureBuilder<MbTilesTileProvider>(
          future: _loadTileProvider(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final tileProvider = snapshot.data!;
              return FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(14.6928, -17.4467), //   Sangalkam
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    tileProvider: tileProvider,
                  ),
                ],
              );
            } else {
              return const Center(child: Text('Aucune donnée disponible'));
            }
          },
        ),
      ),
    );
  }

  Future<MbTilesTileProvider> _loadTileProvider() async {
    return await MbTilesTileProvider.fromPath(
        path: 'assets/tiles/sangalkam.mbtiles'
    );
  }
}