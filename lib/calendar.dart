import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:woyao_app/initDatabaseCalendar.dart';
import 'package:fl_chart/fl_chart.dart';

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

  Color _getSectionColor(int index) {
    // 这里定义一个颜色列表
    List<Color> colors = [
      const Color.fromARGB(120, 244, 67, 54),
      const Color.fromARGB(120, 76, 175, 79),
      const Color.fromARGB(120, 33, 149, 243),
      const Color.fromARGB(120, 255, 153, 0),
      const Color.fromARGB(120, 155, 39, 176),
      const Color.fromARGB(120, 255, 235, 59),
    ];
    return colors[index % colors.length]; // 循环使用颜色列表，防止索引超出范围
  }

  List<PieChartSectionData> _getPieChartData(DateTime date) {
    final List<WoItem> dayEvents = _events[date] ?? [];
    final Map<String, double> durationSum = {};

    for (var event in dayEvents) {
      final List<String> parts = event.duringTime.split(':');
      final double hours = double.parse(parts[0]);
      final double minutes = double.parse(parts[1]);
      final double duration = hours + minutes / 60; // 转换分钟为小时的小数部分

      durationSum.update(event.name, (value) => value + duration, ifAbsent: () => duration);
    }

    // 将总时长转换为饼图数据
    final List<PieChartSectionData> sections = [];
    int index = 0;
    durationSum.forEach((name, totalDuration) {
      sections.add(PieChartSectionData(
        color: _getSectionColor(index), // 使用index来分配颜色
        value: totalDuration,
        title: '$name\n${totalDuration.toStringAsFixed(2)} h', // 格式化显示小时
        radius: 50,
      ));
      index++; // 更新颜色索引
    });

    return sections;
  }


  Widget _buildPieChart(DateTime date) {
    return SizedBox(
      height: 200, 
      width: double.infinity, 
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PieChart(
          PieChartData(
            sections: _getPieChartData(date),
            centerSpaceRadius: 40,
            sectionsSpace: 0,
          ),
        ),
      ),
    );
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
      /// 感觉不整洁，先去掉，顶部栏
      // appBar: AppBar(
      //   backgroundColor: const Color.fromARGB(20, 0, 0, 0),
      //   elevation: 0, 
      //   title: Text(
      //     'Calendar',
      //     style: theme.textTheme.titleLarge?.copyWith(color: Colors.black), 
      //   ),
      // ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.only(top: 20), 
          ),
          SliverToBoxAdapter(
            child: TableCalendar(
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
                todayTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.white),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  // 不渲染任何事件标记,但是好像没啥用呢
                  return null;
                },
                // 为今天自定义装饰
                todayBuilder: (context, date, _) {
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(132, 251, 42, 234),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
                // 为周末自定义装饰
                defaultBuilder: (context, date, _) {
                  if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(119, 42, 146, 251), 
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else {
                    return null;
                  }
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildPieChart(_selectedDay),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final woItem = _events[_selectedDay]?[index];
                return ListTile(
                  title: Text(woItem?.name ?? ''),
                  subtitle: Text("${woItem?.startTime} for ${woItem?.duringTime}"),
                  leading: woItem?.imagePath != null
                      ? Image.file(File(woItem!.imagePath!))
                      : null,
                );
              },
              childCount: _events[_selectedDay]?.length ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildEventsMarker(DateTime date, List events) {
  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     decoration: BoxDecoration(
  //       shape: BoxShape.rectangle,
  //       color: const Color.fromARGB(120, 66, 164, 245),
  //     ),
  //     width: 16.0,
  //     height: 16.0,
  //     child: Center(
  //       child: Text(
  //         '${events.length}',
  //         style: TextStyle().copyWith(
  //           color: Colors.white,
  //           fontSize: 12.0,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    final events = await DBProvider.instance.queryEventsByDate(selectedDay);
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _events = {selectedDay: events};
    });
  }
}