import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class DatabaseHelper {
  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      path.join(dbPath, 'images.db'),
      onCreate: (db, version) {
        return db.execute('CREATE TABLE saved_images(id INTEGER PRIMARY KEY, imagePath TEXT) if not exists');
      },
      version: 1,
    );
  }

  Future<void> insertImagePath(String imagePath) async {
    // final db = await DatabaseHelper.getDatabase();
    // await db.insert(
    //   'saved_images',
    //   {'imagePath': imagePath},
    //   conflictAlgorithm: ConflictAlgorithm.replace,
    // );
  }

  Future<List<String>> getImagePaths() async {
    final db = await DatabaseHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('saved_images');

    return List.generate(maps.length, (i) {
      return maps[i]['imagePath'];
    });
  }

  getItems() {}
}