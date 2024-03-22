import 'package:flutter/material.dart';
import 'main.dart';

class Statistics extends StatelessWidget {
  const Statistics({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Card(
            color: Colors.transparent, 
            shadowColor: Colors.transparent,
            margin: EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Statistics',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
