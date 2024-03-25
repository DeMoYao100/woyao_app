import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';


class DBProvider {
  static final DBProvider _instance = DBProvider._internal();
  Database? _database;

  DBProvider._internal();

  static DBProvider get instance => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    WidgetsFlutterBinding.ensureInitialized();
    final path = join(await getDatabasesPath(), 'WoItemList.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE IF NOT EXISTS WoItemList ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "name TEXT,"
          "imagePath TEXT"
          ")"
        );
      },
    );
  }

  Future<void> insertWoItem(WoItem woItem) async {
    final db = await database;
    await db.insert(
      'WoItemList', 
      woItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WoItem>> queryAllWoItem() async{
    final db = await database;
    final List<Map<String, Object?>> woItemMaps = await db.query('WoItemList');
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryItemsToday() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemList',
      where: '"startTime" BETWEEN ? AND ?',
      whereArgs: [todayStart, todayEnd],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryItemsThisWeek() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = now.add(Duration(days: DateTime.daysPerWeek - now.weekday));

    final weekStartStr = DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();
    final weekEndStr = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemList',
      where: '"startTime" BETWEEN ? AND ?',
      whereArgs: [weekStartStr, weekEndStr],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryItemsThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemList',
      where: '"startTime" BETWEEN ? AND ?',
      whereArgs: [monthStart, monthEnd],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }


  Future<void> deleteWoItem(int id) async {
    final db = await database;
    await db.delete(
      'WoItemList',
      where: 'id = ?',
      whereArgs: [id],
    );
  } 

  Future<void> updateWoItem(WoItem woItem) async {
    final db = await database;
    await db.update(
      'WoItemList',
      woItem.toMap(),
      where: 'id = ?',
      whereArgs: [woItem.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class WoItem {
  int? id;
  String name;
  String? imagePath;
  WoItem({
    this.id,
    required this.name,
    this.imagePath,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
    };
  }

  @override
  String toString() {
    return 'WoItem{id: $id, name: $name, imagePath: $imagePath}';
  }
}
