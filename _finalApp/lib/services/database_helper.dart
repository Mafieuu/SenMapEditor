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

  // Définition des noms de tables
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

    try {
      final data = await rootBundle.load('assets/$fileName');
      final bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    } catch (e) {
      print('Erreur lors de la copie de la base de données : $e');
    }

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
    );
  }

  // Activation des clés étrangères
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Méthode de connexion utilisateur
  Future<User?> getUser(String nom, String paswd) async {
    try {
      final db = await database;
      final maps = await db.query(
        tableUsers,
        columns: ['id', 'nom', 'paswd', 'zone_id'],
        where: 'nom = ? AND paswd = ?',
        whereArgs: [nom, paswd],
        limit: 1,
      );

      return maps.isNotEmpty ? User.fromMap(maps.first) : null;
    } catch (e) {
      print('Erreur lors de la connexion : $e');
      return null;
    }
  }

  Future<Zone?> getZoneById(int zoneId) async {
    final db = await database;
    try {
      final result = await db.query(
        tableZones,
        where: 'id = ?',
        whereArgs: [zoneId],
        limit: 1,
      );

      return result.isNotEmpty ? Zone.fromMap(result.first) : null;
    } catch (e) {
      print('Erreur lors de la récupération de la zone par ID: $e');
      return null;
    }
  }

  // Récupérer les zones d'un utilisateur
  Future<List<Zone>> getZonesByUser(int userId) async {
    final db = await database;
    try {
      final result = await db.query(
        tableZones,
        where: 'utilisateur_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );

      return result.map((json) => Zone.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des zones: $e');
      return [];
    }
  }


  // Récupérer les polygones d'une zone
  Future<List<Polygone>> getPolygonsByZone(int zoneId) async {
    final db = await database;
    try {
      final result = await db.query(
        tablePolygons,
        where: 'zone_id = ?',
        whereArgs: [zoneId],
        orderBy: 'id DESC',
      );

      return result.map((json) => Polygone.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des polygones: $e');
      return [];
    }
  }

  // Insertion d'un polygone
  Future<int> insertPolygone(Polygone polygone) async {
    final db = await database;
    try {
      return await db.insert(tablePolygons, polygone.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion du polygone: $e');
      return -1;
    }
  }

  // Insertion d'un log d'action
  Future<int> insertActionLog(ActionLog actionLog) async {
    final db = await database;
    try {
      return await db.insert(tableCreations, actionLog.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion du log: $e');
      return -1;
    }
  }

  // Insertion d'une zone
  Future<int> insertZone(Zone zone) async {
    final db = await database;
    try {
      return await db.insert(tableZones, zone.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion de la zone: $e');
      return -1;
    }
  }

  // Insertion d'un utilisateur
  Future<int> insertUser(User user) async {
    final db = await database;
    try {
      return await db.insert(tableUsers, user.toMap());
    } catch (e) {
      print('Erreur lors de l\'insertion de l\'utilisateur: $e');
      return -1;
    }
  }

  // Méthode de débogage
  Future<void> debugDatabase() async {
    final db = await database;

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
  // Ajout de la méthode savePolygons
  Future<void> savePolygons(List<Polygone> polygones) async {
    final db = await database;
    Batch batch = db.batch();

    for (Polygone polygone in polygones) {
      batch.insert(
        tablePolygons,
        polygone.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }
  Future<void> debugPolygonGeometry(int zoneId) async {
    final db = await database;
    try {
      final result = await db.query(
        tablePolygons,
        columns: ['id', 'geom'],
        where: 'zone_id = ?',
        whereArgs: [zoneId],
      );

      print('Nombre de polygones : ${result.length}');
      for (var polygon in result) {
        print('Polygone ID: ${polygon['id']}');
        print('Géométrie brute: ${polygon['geom']}');
      }
    } catch (e) {
      print('Erreur lors du débogage des polygones: $e');
    }
  }


  // Méthode pour fermer la base de données
  Future close() async {
    final db = await database;
    db.close();
  }
}