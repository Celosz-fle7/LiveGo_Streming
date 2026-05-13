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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        duration_seconds INTEGER DEFAULT 0,
        last_watched INTEGER NOT NULL,
        platform TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drama_id TEXT NOT NULL UNIQUE,
        drama_title TEXT NOT NULL,
        drama_poster TEXT,
        total_episodes INTEGER DEFAULT 0,
        platform TEXT NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE history ADD COLUMN platform TEXT DEFAULT ""');
      await db.execute('ALTER TABLE favorites ADD COLUMN platform TEXT DEFAULT ""');
    }
  }

  // ==================== RIWAYAT ====================
  Future<void> addToHistory(Map<String, dynamic> history) async {
    final db = await database;
    await db.insert('history', history, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHistoryPosition(String episodeId, int positionSeconds) async {
    final db = await database;
    await db.update(
      'history',
      {'position_seconds': positionSeconds, 'last_watched': DateTime.now().millisecondsSinceEpoch},
      where: 'episode_id = ?',
      whereArgs: [episodeId],
    );
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return await db.query('history', orderBy: 'last_watched DESC', limit: 50);
  }

  Future<Map<String, dynamic>?> getResumeWatching(String dramaId) async {
    final db = await database;
    final result = await db.query(
      'history',
      where: 'drama_id = ?',
      whereArgs: [dramaId],
      orderBy: 'last_watched DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> deleteHistoryItem(int id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }

  // ==================== FAVORIT ====================
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
