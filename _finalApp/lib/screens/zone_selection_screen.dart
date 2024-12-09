import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/error_dialog.dart';
import '../widgets/loading_indicator.dart';

class ZoneSelectionScreen extends StatelessWidget {
  const ZoneSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context); // Ajout du type générique

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sélection de la zone',
        onLogout: () async { // Ajout de async
          await appState.logout();
          if (!context.mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: FutureBuilder<void>( // Ajout du type générique
        future: appState.loadZones(),
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
                  onTap: () async {
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