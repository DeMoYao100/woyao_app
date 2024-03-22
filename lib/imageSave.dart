import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String> saveImage(File image) async {
  final directory = await getApplicationDocumentsDirectory(); // 获取应用文档目录
  final imagePath = path.join(directory.path, 'woyao_images'); // 创建images文件夹路径
  
  // 如果images文件夹不存在，则创建它
  final imageDirectory = Directory(imagePath);
  if (!imageDirectory.existsSync()) {
    imageDirectory.createSync();
  }

  final String fileName = path.basename(image.path); // 获取原始图片的文件名
  final String savedImagePath = path.join(imagePath, fileName); // 创建保存的图片路径
  await image.copy(savedImagePath); // 将图片复制到新路径

  return savedImagePath; // 返回保存后的图片路径
}

