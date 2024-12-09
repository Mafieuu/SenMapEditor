import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // Toujours copier la base de données depuis les assets
    print('Chemin de la base de données : $path');

    try {
      // Charger les données depuis les assets
      final data = await rootBundle.load('assets/$fileName');
      final bytes = data.buffer.asUint8List();

      // Écrire les données dans le chemin de la base de données
      await File(path).writeAsBytes(bytes, flush: true);

      print('Base de données copiée avec succès');
    } catch (e) {
      print('Erreur lors de la copie de la base de données : $e');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Base de données créée. Insertion des données initiales.');
// *************************************************************************
    // Solution temporaire:user par defaut
    // Insérer les utilisateurs par défaut
    await db.transaction((txn) async {
      await txn.rawInsert(
          'INSERT INTO utilisateurs (nom, paswd) VALUES (?, ?), (?, ?), (?, ?), (?, ?)',
          [
            'diouf_abdou221', 'dakar123',

            'diome_fatou221', 'passer',
            'sarr_fellwin221', 'senegal123'
          ]
      );
    });
  }

  // Activation des clés étrangères
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Méthode de débogage
  Future<void> debugDatabase() async {
    final db = await instance.database;

    // Vérifier les tables
    List<Map<String, dynamic>> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print('Tables dans la base de données : $tables');

    // Vérifier les utilisateurs
    List<Map<String, dynamic>> users = await db.query('utilisateurs');
    print('Utilisateurs dans la base de données : $users');

    // Vérifier le nombre d'utilisateurs
    int? userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM utilisateurs'));
    print('Nombre total d\'utilisateurs : $userCount');
  }

  Future<User?> getUser(String nom, String paswd) async {
    try {
      // Déboguer la base de données avant la tentative de connexion
      await debugDatabase();

      final db = await instance.database;

      print('Tentative de connexion - Nom: $nom, Mot de passe: $paswd');

      final maps = await db.query(
        tableUsers,
        columns: ['id', 'nom', 'paswd'],
        where: 'nom = ? AND paswd = ?',
        whereArgs: [nom, paswd],
        limit: 1,
      );

      print('Résultats de la requête : ${maps.length}');

      return maps.isNotEmpty ? User.fromMap(maps.first) : null;
    } catch (e) {
      print('Erreur lors de la connexion : $e');
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