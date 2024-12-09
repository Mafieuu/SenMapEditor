import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/zone.dart';
import '../models/polygone.dart';
import '../models/action_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String tableUsers = 'utilisateurs';
  static const String tableZones = 'zones';
  static const String tablePolygons = 'polygones';
  static const String tableCreations = 'creations';
  static const String tableDeletions = 'suppressions';
  static const String tableModifications = 'modifications';
  static const String tableFusions = 'fusions';
  static const String tableDivisions = 'divisions';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('database.db');
    return _database!;
  }
// Sqlite ne peut pas lire les fichiers present dans asset

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath(); // Chemin où SQLite peut lire et écrire
    final path = join(dbPath, fileName);
    // TODO: suprimmer les print de debogage
    print('Chemin de la base de données : $path');
    print('Le fichier existe ? : ${await File(path).exists()}');

    // Vérifiez si le fichier existe déjà
    final exists = await File(path).exists();
    if (!exists) {
      print('Tentative de copie depuis assets');
      final data = await rootBundle.load('assets/$fileName');
      final bytes = data.buffer.asUint8List();

      // Créez le fichier et écrivez les données
      await File(path).writeAsBytes(bytes);
      print('Fichier copié avec succès');
    }
    return await openDatabase(
      path,
      version: 1,
      onCreate: null,
      onConfigure: _onConfigure,
    );
  }

  // Activation des clés étrangères
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Méthodes CRUD existantes

  Future<User?> getUser(String nom, String paswd) async {
    try {
    final db = await instance.database;
    print('Base de données ouverte avec succès');

      // debogage

      // Verifions  si la table existe
      var tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      print('Tables existantes : $tables');


    // Vérifier le schéma de la table utilisateurs
    List<Map<String, dynamic>> columns = await db.rawQuery("PRAGMA table_info(utilisateurs)");
    print('Colonnes de la table utilisateurs : $columns');

    // Afficher tous les utilisateurs
    List<Map<String, dynamic>> allUsers = await db.query(tableUsers);
    print('Tous les utilisateurs : $allUsers');
      //  avant la requête
      print('--------------------------------- Tentative de connexion:');
      print('Nom recherché: $nom');
      print('Mot de passe recherché: $paswd');

      print('Recherche de l\'utilisateur - Nom: $nom, Mot de passe: $paswd');
      final maps = await db.query(
        tableUsers,
        columns: ['id', 'nom', 'paswd'],
        where: 'nom = ? AND paswd = ?',
        whereArgs: [nom, paswd],
        limit: 1,
      );
      // résultat de la requête
      print(' ***************************************************** Résultats de la requête:');
      print('Nombre de résultats: ${maps.length}');
      maps.forEach((map) => print('Utilisateur trouvé: $map'));

      return maps.isNotEmpty ? User.fromMap(maps.first) : null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  Future<List<Zone>> getZonesByUser(int userId) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        tableZones,
        where: 'utilisateur_id = ?',
        whereArgs: [userId],
        orderBy: 'date_creation DESC',
      );

      return result.map((json) => Zone.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des zones: $e');
      return [];
    }
  }

  Future<List<Polygone>> getPolygonsByZone(int zoneId) async {
    final db = await instance.database;
    try {
      final result = await db.query(
        tablePolygons,
        where: 'zone_id = ?',
        whereArgs: [zoneId],
        orderBy: 'date_creation DESC',
      );

      return result.map((json) => Polygone.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des polygones: $e');
      return [];
    }
  }

  // Insertion d'un polygone
  Future<int> insertPolygone(Polygone polygone) async {
    final db = await instance.database;
    try {
      return await db.insert(tablePolygons, polygone.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion du polygone: $e');
      return -1;
    }
  }

  // Insertion d'un log d'action
  Future<int> insertActionLog(ActionLog actionLog) async {
    final db = await instance.database;
    try {
      return await db.insert(tableCreations, actionLog.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion du log: $e');
      return -1;
    }
  }

  // Méthodes supplémentaires pour gérer les autres tables

  Future<int> insertZone(Zone zone) async {
    final db = await instance.database;
    try {
      return await db.insert(tableZones, zone.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion de la zone: $e');
      return -1;
    }
  }

  Future<int> insertUser(User user) async {
    final db = await instance.database;
    try {
      return await db.insert(tableUsers, user.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion de l\'utilisateur: $e');
      return -1;
    }
  }

  // Méthode pour fermer la base de données
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}