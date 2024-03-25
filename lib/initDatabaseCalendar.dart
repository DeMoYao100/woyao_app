import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

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
    final path = join(await getDatabasesPath(), 'WoItemCalender.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE IF NOT EXISTS WoItemCalender ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "name TEXT,"
          "imagePath TEXT,"
          "duringTime TEXT,"
          "startTime TEXT DEFAULT CURRENT_TIMESTAMP"
          ")",
        );
      },
    );
  }

  Future<void> insertWoItem(WoItem woItem) async {
    final db = await database;
    await db.insert(
      'WoItemCalender', 
      woItem.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WoItem>> queryAllWoItem() async{
    final db = await database;
    final List<Map<String, Object?>> woItemMaps = await db.query('WoItemCalender');
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        duringTime: woItemMap['duringTime'] as String,
        startTime: woItemMap['startTime'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

    Future<List<WoItem>> queryItemsToday() async {
    final db = await database;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemCalender',
      where: 'DATE(startTime) = ?',
      whereArgs: [dateStr],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        duringTime: woItemMap['duringTime'] as String,
        startTime: woItemMap['startTime'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryEventsByDate(DateTime date) async {
    final db = await database; // 确保你有一个获取当前数据库实例的方法
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemCalender', // 确保这是你的表名
      where: 'DATE(startTime) = ?',
      whereArgs: [dateString],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        duringTime: woItemMap['duringTime'] as String,
        startTime: woItemMap['startTime'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryItemsThisWeek() async {
    final db = await database;
    final now = DateTime.now();
    // 计算周的开始（周一）
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    // 计算周的结束（周日）
    final weekEnd = now.add(Duration(days: 7 - now.weekday));

    final weekStartStr = DateFormat('yyyy-MM-dd').format(weekStart);
    final weekEndStr = DateFormat('yyyy-MM-dd').format(weekEnd);

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemList',
      where: 'DATE(startTime) BETWEEN ? AND ?',
      whereArgs: [weekStartStr, weekEndStr],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        duringTime: woItemMap['duringTime'] as String,
        startTime: woItemMap['startTime'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryEventsByWeek(DateTime weekStart, DateTime weekEnd) async {
    final db = await database;
    final startString = DateFormat('yyyy-MM-dd').format(weekStart);
    final endString = DateFormat('yyyy-MM-dd').format(weekEnd);

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemCalender',
      where: 'DATE(startTime) >= ? AND DATE(startTime) <= ?',
      whereArgs: [startString, endString],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        duringTime: woItemMap['duringTime'] as String,
        startTime: woItemMap['startTime'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryItemsThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final monthStartStr = DateFormat('yyyy-MM-dd').format(monthStart);
    final monthEndStr = DateFormat('yyyy-MM-dd').format(monthEnd);

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemList',
      where: 'DATE(startTime) BETWEEN ? AND ?',
      whereArgs: [monthStartStr, monthEndStr],
    );
    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        duringTime: woItemMap['duringTime'] as String,
        startTime: woItemMap['startTime'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

  Future<List<WoItem>> queryEventsByMonth(int year, int month) async {
    final db = await database;
    final startDateString = DateFormat('yyyy-MM-dd').format(DateTime(year, month, 1));
    final endDateString = DateFormat('yyyy-MM-dd').format(DateTime(year, month + 1, 0));

    final List<Map<String, dynamic>> woItemMaps = await db.query(
      'WoItemCalender',
      where: '"startTime" BETWEEN ? AND ?',
      whereArgs: [startDateString, endDateString],
    );

    return woItemMaps.map((woItemMap) {
      return WoItem(
        id: woItemMap['id'] as int?,
        name: woItemMap['name'] as String,
        duringTime: woItemMap['duringTime'] as String,
        startTime: woItemMap['startTime'] as String,
        imagePath: woItemMap['imagePath'] as String?,
      );
    }).toList();
  }

 
  Future<void> deleteWoItem(int id) async {
    final db = await database;
    await db.delete(
      'WoItemCalender',
      where: 'id = ?',
      whereArgs: [id],
    );
  } 

  Future<void> updateWoItem(WoItem woItem) async {
    final db = await database;
    await db.update(
      'WoItemCalender',
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
  String duringTime;
  String startTime;

  WoItem({
    this.id,
    required this.name,
    required this.duringTime,
    required this.startTime,
    this.imagePath,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'duringTime': duringTime,
      'imagePath': imagePath,
      'startTime': startTime,
    };
  }

  @override
  String toString() {
    return 'WoItem{id: $id, name: $name, duringTime: $duringTime, imagePath: $imagePath, startTime: $startTime}';
  }
}
