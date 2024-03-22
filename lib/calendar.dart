import 'package:flutter/material.dart';
import 'main.dart';

class Calendar extends StatelessWidget {
  const Calendar({Key? key}) : super(key: key);
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
                'Calendar',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}