import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:woyao_app/imageDatebase.dart';
import 'package:woyao_app/imageSave.dart';

class BackgroundManager with ChangeNotifier {
  String? _currentBackground;

  String? get currentBackground => _currentBackground;

  Future<void> selectBackground() async {
    final ImagePicker _picker = ImagePicker();
    // 从图库中选择图片
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    // 如果选择了图片，则更新背景路径并通知监听器
    if (image != null) {
      final File imageFile = File(image.path);
      final String savedImagePath = await saveImage(imageFile); // 保存图片到应用目录
      await DatabaseHelper().insertImagePath(savedImagePath); // 将图片路径保存到数据库
      _currentBackground = image.path;
      notifyListeners();
    }
  }
}