import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  static Database? _database;

  CacheService._internal();

  factory CacheService() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}/livego_cache.db';
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE api_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');
  }

  // Simpan data ke cache dengan TTL (menit)
  Future<void> set(String key, dynamic data, {int ttlMinutes = 30}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + (ttlMinutes * 60 * 1000);
    
    await db.insert(
      'api_cache',
      {
        'key': key,
        'data': json.encode(data),
        'created_at': now,
        'expires_at': expiresAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Ambil data dari cache jika belum expired
  Future<dynamic> get(String key) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final List<Map<String, dynamic>> result = await db.query(
      'api_cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, now],
    );
    
    if (result.isNotEmpty) {
      return json.decode(result.first['data']);
    }
    return null;
  }

  // Hapus cache expired
  Future<void> clearExpired() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete('api_cache', where: 'expires_at <= ?', whereArgs: [now]);
  }

  // Hapus semua cache
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('api_cache');
  }
}
