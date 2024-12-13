import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_dialog.dart';

// Ecran de connexion
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // cle pour gerer le formulaire
  final _formKey = GlobalKey<FormState>();
  
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Libérer les ressources des controleurs
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // validation  username
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre identifiant';
    }
    return null;
  }

  // validation password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  // methode de connexion
  Future<void> _login() async {
  
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // tenter de se connecter via le provider
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final success = await appState.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // résultat de la connexion
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorDialog('Identifiant ou mot de passe incorrect.');
      }
    } catch (e) {
      _showErrorDialog('Une erreur est survenue. Veuillez réessayer.');
    } finally {
      // Désactiver l'indicateur de chargement
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // dialogue d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(message: message),
    );
  }

  // new:dialogue d'aide
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aide à la Connexion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pour des besoins de test, vous pouvez utiliser :'),
              const SizedBox(height: 10),
              const Text('Identifiant : sarr_felwine'),
              const Text('Mot de passe : dakar123'),
              const SizedBox(height: 15),
              const Text(
                "Note : L'utulisateur sarr_felwine est affecte au district de  sangalkam.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        elevation: 0,
        // new: bouton d'aide 
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Aide à la connexion',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      const Icon(
                        Icons.map,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 40),
                      // Titre de l'application
                      const Text(
                        'SenMapEditor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Champ de saisie de l'identifiant
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Identifiant',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: _validateUsername,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                      ),
                      const SizedBox(height: 20),
                      // Champ de saisie du mot de passe
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 30),
                      // Bouton de connexion
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}