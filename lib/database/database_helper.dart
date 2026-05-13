import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}/livego.db';
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drama_id TEXT NOT NULL,
        drama_title TEXT NOT NULL,
        drama_poster TEXT,
        episode_id TEXT NOT NULL,
        episode_number INTEGER NOT NULL,
        position_seconds INTEGER DEFAULT 0,
        last_watched INTEGER NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drama_id TEXT NOT NULL UNIQUE,
        drama_title TEXT NOT NULL,
        drama_poster TEXT,
        total_episodes INTEGER DEFAULT 0,
        added_at INTEGER NOT NULL
      )
    ''');
  }

  // Riwayat
  Future<void> addToHistory(Map<String, dynamic> history) async {
    final db = await database;
    await db.insert('history', history, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return await db.query('history', orderBy: 'last_watched DESC', limit: 50);
  }

  Future<void> deleteHistoryItem(int id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }

  // Favorit
  Future<void> addToFavorites(Map<String, dynamic> favorite) async {
    final db = await database;
    await db.insert('favorites', favorite, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFromFavorites(String dramaId) async {
    final db = await database;
    await db.delete('favorites', where: 'drama_id = ?', whereArgs: [dramaId]);
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final db = await database;
    return await db.query('favorites', orderBy: 'added_at DESC');
  }

  Future<bool> isFavorite(String dramaId) async {
    final db = await database;
    final result = await db.query('favorites', where: 'drama_id = ?', whereArgs: [dramaId]);
    return result.isNotEmpty;
  }

  Future<void> clearFavorites() async {
    final db = await database;
    await db.delete('favorites');
  }
}
