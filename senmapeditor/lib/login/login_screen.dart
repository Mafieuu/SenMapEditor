import 'package:flutter/material.dart';
import 'database_helper.dart';
// TODO: A implementer
class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void authenticate(BuildContext context) async {
    final db = DatabaseHelper();
    final username = usernameController.text;
    final password = passwordController.text;

    final user = await db.getUser(username, password);
    if (user != null) {
      // Naviguer vers l'écran principal en passant le GeoJSON correspondant
      Navigator.pushReplacementNamed(
        context,
        '/geojson',
        arguments: user['geojson'], // Transmet le GeoJSON
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Identifiants incorrects")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            ElevatedButton(
              onPressed: () => authenticate(context),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
