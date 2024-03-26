import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';
Future<void> requestPermissions() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
}

Future<void> importDatabaseFromJson() async {
  await requestPermissions();
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    String path = result.files.single.path!;
    String content = await File(path).readAsString();
    List<dynamic> data = jsonDecode(content);
    Database db = await openDatabase('WoItemCalendar.db');
    Batch batch = db.batch();
    for (var item in data) {
      // 移除item中的id字段
      Map<String, dynamic> newItem = Map<String, dynamic>.from(item);
      newItem.remove('id'); // 假设你的原始数据包含id字段，如果不包含，则不需要这一行
      batch.insert('WoItemCalendar', newItem);
    }
    await batch.commit();

    print('Data imported from $path');
  } else {
    print('No file selected');
  }
}


Future<void> exportDatabaseToJson() async {

  Database db = await openDatabase('WoItemCalendar.db');

  List<Map> results = await db.query('WoItemCalendar');

  String jsonData = jsonEncode(results);

  final directory = await getExternalStorageDirectory();
  String path = '${directory!.path}/woItemCalendarData.json';

  File file = File(path);
  await file.writeAsString(jsonData);

  print('Data exported to $path');
  // 在这里，你可以选择通过UI向用户展示文件路径
}