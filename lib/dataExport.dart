import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<void> importDatabaseFromJson() async {
  // 让用户选择一个文件
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    String path = result.files.single.path!;
    // 读取文件内容
    String content = await File(path).readAsString();
    List<dynamic> data = jsonDecode(content);

    // 获取数据库实例
    Database db = await openDatabase('your_database_path');

    // 可选：清空当前的表
    await db.delete('WoItemCalender');

    // 将数据批量插入到数据库
    Batch batch = db.batch();
    for (var item in data) {
      batch.insert('WoItemCalender', item);
    }
    await batch.commit();

    print('Data imported from $path');
    // 在这里，你可以更新UI通知用户数据导入完成
  } else {
    // 用户未选择文件
    print('No file selected');
  }
}

Future<void> exportDatabaseToJson() async {
  
  Database db = await openDatabase('your_database_path');

  List<Map> results = await db.query('WoItemCalender');

  // 转换数据为JSON格式的字符串
  String jsonData = jsonEncode(results);

  // 获取存储路径
  final directory = await getExternalStorageDirectory();
  String path = '${directory!.path}/woItemCalenderData.json';

  // 将JSON数据写入文件
  File file = File(path);
  await file.writeAsString(jsonData);

  print('Data exported to $path');
  // 在这里，你可以选择通过UI向用户展示文件路径
}