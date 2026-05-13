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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE api_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        data_size INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE api_cache ADD COLUMN data_size INTEGER DEFAULT 0');
    }
  }

  // Hitung total cache dalam MB
  Future<double> getTotalCacheSizeMB() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(data_size) as total_size FROM api_cache
    ''');
    final totalBytes = (result.first['total_size'] ?? 0) as int;
    return totalBytes / (1024 * 1024); // Konversi ke MB
  }

  // Auto clean cache jika melebihi batas 500MB
  Future<void> autoCleanIfNeeded() async {
    final totalMB = await getTotalCacheSizeMB();
    print("Total cache: ${totalMB.toStringAsFixed(2)} MB");
    
    if (totalMB >= 500) {
      print("Cache melebihi 500MB, auto cleaning...");
      await _cleanOldCache(targetMB: 300);
    }
  }

  // Hapus cache tertua sampai target MB tercapai
  Future<void> _cleanOldCache({int targetMB = 300}) async {
    final db = await database;
    int targetBytes = targetMB * 1024 * 1024;
    
    while (true) {
      final currentSize = await getTotalCacheSizeMB();
      if (currentSize <= targetMB) break;
      
      // Ambil cache tertua (created_at paling kecil)
      final oldest = await db.query(
        'api_cache',
        orderBy: 'created_at ASC',
        limit: 10,
      );
      
      if (oldest.isEmpty) break;
      
      // Hapus 10 cache tertua
      for (var item in oldest) {
        await db.delete('api_cache', where: 'id = ?', whereArgs: [item['id']]);
        print("Deleted old cache: ${item['key']}");
      }
    }
    
    final newSize = await getTotalCacheSizeMB();
    print("Auto clean selesai. Cache sekarang: ${newSize.toStringAsFixed(2)} MB");
  }

  // Simpan data ke cache (otomatis hitung ukuran)
  Future<void> set(String key, dynamic data, {int ttlMinutes = 30}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + (ttlMinutes * 60 * 1000);
    
    final jsonString = json.encode(data);
    final dataSize = utf8.encode(jsonString).length;
    
    await db.insert(
      'api_cache',
      {
        'key': key,
        'data': jsonString,
        'created_at': now,
        'expires_at': expiresAt,
        'data_size': dataSize,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Cek auto clean setelah insert
    await autoCleanIfNeeded();
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

  // Hapus semua cache (manual jika diperlukan)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('api_cache');
    print("All cache cleared");
  }
}
