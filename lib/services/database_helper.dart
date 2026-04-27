import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'timetable_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE timetable_cache(id TEXT PRIMARY KEY, type TEXT, data TEXT, timestamp INTEGER)',
        );
      },
    );
  }

  // Convert Firestore data (with Timestamps) to JSON-safe format
  dynamic _convertFirestoreData(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key, _convertFirestoreData(value)));
    } else if (data is List) {
      return data.map((item) => _convertFirestoreData(item)).toList();
    }
    return data;
  }

  Future<void> insertOrUpdateTimetable(
      String id, String type, Map<String, dynamic> data) async {
    try {
      final db = await database;
      final convertedData = _convertFirestoreData(data);
      await db.insert(
        'timetable_cache',
        {
          'id': id,
          'type': type,
          'data': json.encode(convertedData),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  Future<Map<String, dynamic>?> getTimetable(String id, String type) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'timetable_cache',
        where: 'id = ? AND type = ?',
        whereArgs: [id, type],
      );
      if (maps.isNotEmpty) {
        return json.decode(maps.first['data'] as String) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error reading from cache: $e');
      return null;
    }
  }

  Future<bool> isCacheFresh(String id, String type,
      {int minutesThreshold = 5}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'timetable_cache',
        where: 'id = ? AND type = ?',
        whereArgs: [id, type],
      );
      if (maps.isEmpty) return false;
      final cachedTimestamp = maps.first['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final difference = now - cachedTimestamp;
      final minutesDifference = difference / (1000 * 60);
      return minutesDifference < minutesThreshold;
    } catch (e) {
      print('Error checking cache freshness: $e');
      return false;
    }
  }

  Future<bool> hasCache(String id, String type) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'timetable_cache',
        where: 'id = ? AND type = ?',
        whereArgs: [id, type],
      );
      return maps.isNotEmpty;
    } catch (e) {
      print('Error checking cache: $e');
      return false;
    }
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('timetable_cache');
  }

  Future<void> deleteTimetable(String id, String type) async {
    final db = await database;
    await db.delete(
      'timetable_cache',
      where: 'id = ? AND type = ?',
      whereArgs: [id, type],
    );
  }
}
