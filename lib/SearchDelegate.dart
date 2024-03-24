import 'package:flutter/material.dart';
import 'initDatabaseList.dart';
import 'initDatabaseCalender.dart' as databaseCalender;

class CustomSearchDelegate extends SearchDelegate {
  final List<WoItem> items;

  CustomSearchDelegate(this.items);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where((item) =>
      item.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index].name),
          onTap: () {
            navigateToTodayPage(context, results[index]);
            close(context, results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = items.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index].name),
          onTap: () {
            query = suggestions[index].name;
            navigateToTodayPage(context, suggestions[index]);
          },
        );
      },
    );
  }

  void navigateToTodayPage(BuildContext context, WoItem item) async {
    final newItem = databaseCalender.WoItem(name: item.name, duringTime: "0", startTime: DateTime.now().toString(),imagePath: item.imagePath);
    await databaseCalender.DBProvider.instance.insertWoItem(newItem);
  }
}
