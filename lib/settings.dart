import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'background_manager.dart'; // 引入背景管理器

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // 使用Provider来访问BackgroundManager实例
    final backgroundManager = Provider.of<BackgroundManager>(context, listen: false);

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Card(
            color:Colors.transparent,
            shadowColor: Colors.transparent,
            margin: EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Settings',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          ElevatedButton(
            
            onPressed: () => backgroundManager.selectBackground(), // 切换背景图
            child: Text('Toggle Background'),
          ),
        ],
      ),
    );
  }
}
