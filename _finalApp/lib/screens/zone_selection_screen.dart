import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_indicator.dart';

class ZoneSelectionScreen extends StatefulWidget {
  const ZoneSelectionScreen({super.key});

  @override
  State<ZoneSelectionScreen> createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  late Future<void> _loadZonesFuture;

  @override
  void initState() {
    super.initState();
    _loadZonesFuture = _loadZones();
  }

  Future<void> _loadZones() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await appState.loadZones();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sélection de la zone',
        onLogout: () {
          appState.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: FutureBuilder<void>(
        future: _loadZonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return Center(
              child: ErrorDialog(
                message: 'Erreur de chargement des zones: ${snapshot.error}',
              ),
            );
          }

          if (appState.zones.isEmpty) {
            return const Center(
              child: Text('Aucune zone disponible'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: appState.zones.length,
            itemBuilder: (context, index) {
              final zone = appState.zones[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.map),
                  title: Text(zone.nom),
                  subtitle: Text('Zone ID: ${zone.id}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    appState.setCurrentZone(zone);
                    Navigator.pushNamed(context, '/map');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}