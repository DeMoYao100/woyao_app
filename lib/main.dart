import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:noyao/settings.dart';
import 'package:noyao/today.dart';
import 'calendar.dart';
import 'background_manager.dart';
import 'statistics.dart';
import 'addList.dart';
import 'settings.dart';
import 'dart:io';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BackgroundManager(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaOut',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      builder: (context, child) {
        final backgroundManager = Provider.of<BackgroundManager>(context);
        final backgroundPath = backgroundManager.currentBackground;
        return Container(
          decoration: BoxDecoration(
            image: backgroundPath != null
                ? DecorationImage(
                    image: FileImage(File(backgroundPath)),
                    fit: BoxFit.cover,
                  )
                : DecorationImage(
                    image: AssetImage("assets/background.png"),
                    fit: BoxFit.cover,
                  ),
          ),
          child: child,
        );
      },
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Color.fromARGB(130, 190, 244, 254),
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.add_chart_outlined),
            icon: Icon(Icons.add_chart),
            label: 'statistics',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.calendar_month),
            icon: Icon(Icons.calendar_month_outlined),
            label: 'calendar',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'today',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.add),
            icon: Icon(Icons.add_outlined),
            label: 'add title',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'settings',
          ),
        ],
      ),
      
      body: <Widget>[
        Statistics(),
        Calendar(),
        Today(),
        AddList(),
        Settings(),        
      ][_selectedIndex],
    );
  }
}
