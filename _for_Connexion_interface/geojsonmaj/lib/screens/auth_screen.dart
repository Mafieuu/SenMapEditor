import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'geojson_map_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLogin = true;
  String? _selectedZone;
  final List<String> _zones = ['Sangalkam', 'Autre Zone 1', 'Autre Zone 2'];

  final Map<String, Map<String, double>> _zoneCoordinates = {
    'Sangalkam':  {'latitude': 14.80046963, 'longitude': -17.24228481},
    'Autre Zone 1': {'latitude': 14.70046963, 'longitude': -17.34228481},
    'Autre Zone 2': {'latitude': 14.60046963, 'longitude': -17.44228481}, };

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLogin) {
      // Connexion
      final user = await _authService.login(
          _usernameController.text,
          _passwordController.text
      );

      if (user != null) {
        // Vérifier le fichier GeoJSON local
        final isLocalFilePresent = await _authService.checkLocalGeojsonFile(user.zone);

        if (isLocalFilePresent) {
          // Naviguer vers l'écran de carte
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => GeoJsonMapScreen(user: user))
          );
        } else {
          // TODO: Implémenter le téléchargement du fichier GeoJSON
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Téléchargement du fichier GeoJSON requis'))
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identifiants incorrects'))
        );
      }
    } else {
      // Partie inscription
      if (_selectedZone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner une zone'))
        );
        return;
      }

      final user = User(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          zone: _selectedZone!,
          initialCenter: _zoneCoordinates[_selectedZone!]!
      );

      final success = await _authService.register(user);

      if (success) {
        // Connexion automatique après inscription
        final loggedInUser = await _authService.login(
            _usernameController.text,
            _passwordController.text
        );

        if (loggedInUser != null) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => GeoJsonMapScreen(user: loggedInUser))
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l\'inscription'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Connexion' : 'Inscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (value) => value!.isEmpty ? 'Prénom requis' : null,
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (value) => value!.isEmpty ? 'Nom requis' : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Zone'),
                    value: _selectedZone,
                    items: _zones.map((zone) =>
                        DropdownMenuItem(
                            value: zone,
                            child: Text(zone)
                        )
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedZone = value;
                      });
                    },
                    validator: (value) => value == null ? 'Zone requise' : null,
                  ),
                ],
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Pseudonyme'),
                  validator: (value) => value!.isEmpty ? 'Pseudonyme requis' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Mot de passe requis' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _authenticate,
                  child: Text(_isLogin ? 'Connexion' : 'Inscription'),
                ),
                TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(_isLogin
                      ? 'Pas de compte ? Inscrivez-vous'
                      : 'Déjà un compte ? Connectez-vous'
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}