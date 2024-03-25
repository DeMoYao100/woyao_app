import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:woyao_app/initDatabaseCalendar.dart';

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late Map<DateTime, List<WoItem>> _events;
  late DateTime _selectedDay = DateTime.now();
  late DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _events = {};
    _loadWoItems();
  }

  void _loadWoItems() async {
    final allWoItems = await DBProvider.instance.queryItemsToday();
    final Map<DateTime, List<WoItem>> loadedEvents = {};
    for (var woItem in allWoItems) {
      final DateTime start = DateTime.parse(woItem.startTime);
      if (loadedEvents[start] == null) loadedEvents[start] = [];
      loadedEvents[start]!.add(woItem);
    }
    setState(() {
      _events = loadedEvents;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(20, 0, 0, 0),
        elevation: 0, 
        title: Text(
          'Calendar',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.black), 
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            eventLoader: (day) => _events[day] ?? [],
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _onDaySelected(selectedDay, focusedDay);
            },
            calendarStyle: CalendarStyle(
              // Customize calendar style here
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
              },
            ),
          ),
          Expanded(
            child: _events[_selectedDay]?.isNotEmpty == true
                ? ListView.builder(
                    itemCount: _events[_selectedDay]!.length,
                    itemBuilder: (context, index) {
                      final woItem = _events[_selectedDay]![index];
                      return ListTile(
                        title: Text(woItem.name),
                        subtitle: Text("${woItem.startTime} for ${woItem.duringTime}"),
                        leading: woItem.imagePath != null 
                                ? Image.file(File(woItem.imagePath!))
                                : null,
                        // 在这里添加其他字段显示，根据需要调整
                        // todo: onTap: , 显示detail
                      );
                    },
                  )
                : Center(child: Text('No Events on Selected Day')),
          ),

        ],
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: const Color.fromARGB(120, 66, 164, 245),
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

    void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    final events = await DBProvider.instance.queryEventsByDate(selectedDay);
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _events = {selectedDay: events};
    });
  }
}
