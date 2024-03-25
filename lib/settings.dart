import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'background_manager.dart'; // 引入背景管理器

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundManager = Provider.of<BackgroundManager>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(20, 0, 0, 0),
        elevation: 0, 
        title: Text(
          'Settings', // 这里改为了'Settings'，因为看起来你是在设置页面
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView(
          children: [
            TextButton(
              onPressed: () => backgroundManager.selectBackground(),
              child: Text('Toggle Background', style: TextStyle(color: Colors.blue)),
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Color.fromARGB(130, 65, 172, 255)),
                backgroundColor: MaterialStateProperty.all(Color.fromARGB(60, 65, 172, 255)),
                foregroundColor: MaterialStateProperty.all(Colors.blue),
                shadowColor: MaterialStateProperty.all(Colors.transparent),
              ),
            ),
            // 添加更多的按钮或其他元素
          ],
        ),
      ),
    );
  }
}
