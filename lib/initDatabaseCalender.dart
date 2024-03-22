import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/widgets.dart';


// void main() async{
//   WidgetsFlutterBinding.ensureInitialized(); 
//   final newItem = WoItem(name: "test", duringTime: "0", startTime: DateTime.now().toString(),imagePath: "test");
//   final dbProvider = DBProvider.instance;
//   await dbProvider.insertWoItem(newItem); // 等待插入完成
//   await dbProvider.queryAllWoItem(); 
// }


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
