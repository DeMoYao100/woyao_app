import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:woyao_app/background_manager.dart';
import 'package:woyao_app/today.dart';
import 'main.dart';
import 'package:provider/provider.dart';
import 'initDatabaseCalendar.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';
import 'initDatabaseCalendar.dart';

class DateRangeItems {
  DateTime startDate;
  DateTime endDate;
  List<WoItem>? items;

  DateRangeItems({
    required this.startDate,
    required this.endDate,
    this.items,
  });

  Future<void> updateItemsByInterval(DateTime startDay, DateTime endDay) async {
    items = await DBProvider.instance.queryEventsByInterval(startDay, endDay);
  }
}

class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);
  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  late String _selectedPattern;
  late DateTime _selectedDay = DateTime.now();
  late DateRangeItems _events;

  @override
  void initState() {
    super.initState();
    _selectedPattern = "";
    _selectedDay = DateTime.now();
    _events = DateRangeItems(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      items: [],
    );
  }

  Color _getSectionColor(int index) {
    List<Color> colors = [
      const Color.fromARGB(120, 244, 67, 54),
      const Color.fromARGB(120, 76, 175, 79),
      const Color.fromARGB(120, 33, 149, 243),
      const Color.fromARGB(120, 255, 153, 0),
      const Color.fromARGB(120, 155, 39, 176),
      const Color.fromARGB(120, 255, 235, 59),
    ];
    return colors[index % colors.length]; 
  }

  List<PieChartSectionData> _getPieChartData() {
    final List<WoItem> dayEvents = _events.items ?? [];
    final Map<String, double> durationSum = {};
    for (var event in dayEvents) {
      final List<String> parts = event.duringTime.split(':');
      final double hours = double.parse(parts[0]);
      final double minutes = double.parse(parts[1]);
      final double duration = hours + minutes / 60; 
      durationSum.update(event.name, (value) => value + duration, ifAbsent: () => duration);
    }
    // 将总时长转换为饼图数据
    final List<PieChartSectionData> sections = [];
    int index = 0;
    durationSum.forEach((name, totalDuration) {
      sections.add(PieChartSectionData(
        color: _getSectionColor(index),
        value: totalDuration,
        title: '$name\n${totalDuration.toStringAsFixed(2)} h', 
        radius: 50,
      ));
      index++;
    });
    return sections;
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 200, 
      width: double.infinity, 
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PieChart(
          PieChartData(
            sections: _getPieChartData(),
            centerSpaceRadius: 40,
            sectionsSpace: 0,
          ),
        ),
      ),
    );
  }

  int _getCurrentWeekIndex() {
    List<String> weekList = _generateWeekList();
    
    for (int i = 0; i < weekList.length; i++) {
      String week = weekList[i];
      int year = int.parse(week.split('    :   ')[0]);
      String datesPart = week.split(':   ')[1]; 
      List<String> dates = datesPart.split(' - '); 
      DateTime startOfWeek = DateTime(
        year,
        int.parse(dates[0].split('/')[0]),
        int.parse(dates[0].split('/')[1]),
      );
      DateTime endOfWeek = DateTime( /// 注意跨年处理，&&这个包感觉有热重载不完全的问题，中间有调试出一个稳定触发的year+1的问题（就是这个函数里面），感觉是热重载一部分没载上，甚至不一定是热重载，因为重启过一两次也稳定触发了...
        year + (int.parse(dates[0].split('/')[0]) > int.parse(dates[1].split('/')[0]) ? 1 : 0),
        int.parse(dates[1].split('/')[0]),
        int.parse(dates[1].split('/')[1]),
      );
      if ((_selectedDay.isAfter(startOfWeek) || _selectedDay.isAtSameMomentAs(startOfWeek)) &&
          (_selectedDay.isBefore(endOfWeek) || _selectedDay.isAtSameMomentAs(endOfWeek))) {
        initChart(startOfWeek, endOfWeek);
        return i; 
      }
    }
    return 0;
  }

  int _getCurrentMonthIndex() {
    List<String> monthList = _generateMonthList();
    
    for (int i = 0; i < monthList.length; i++) {
      String month = monthList[i];
      int year = int.parse(month.split('    :   ')[0]);
      String datesPart = month.split(':   ')[1]; 
      List<String> dates = datesPart.split(' - '); 
      DateTime startOfmonth = DateTime(
        year,
        int.parse(dates[0].split('/')[0]),
        int.parse(dates[0].split('/')[1]),
      );
      DateTime endOfmonth = DateTime( 
        year,
        int.parse(dates[1].split('/')[0]),
        int.parse(dates[1].split('/')[1]),
      );
      if ((_selectedDay.isAfter(startOfmonth) || _selectedDay.isAtSameMomentAs(startOfmonth)) &&
          (_selectedDay.isBefore(endOfmonth) || _selectedDay.isAtSameMomentAs(endOfmonth))) {
        initChart(startOfmonth, endOfmonth);
        return i; 
      }
    }
    return 0;
  }

  int _getCurrentYearIndex() {
    List<String> yearList = _generateYearList();
    
    for (int i = 0; i < yearList.length; i++) {
      String date = yearList[i];
      int year = int.parse(date.split('    :   ')[0]);
      DateTime startOfyear = DateTime(year,1,1);
      DateTime endOfyear = DateTime(year+1,1,0);
      if ((_selectedDay.isAfter(startOfyear) || _selectedDay.isAtSameMomentAs(startOfyear)) &&
          (_selectedDay.isBefore(endOfyear) || _selectedDay.isAtSameMomentAs(endOfyear))) {
        initChart(startOfyear, endOfyear);
        return i; 
      }
    }
    return 0;
  }

  void _showWeekPicker(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Color.fromARGB(48, 255, 255, 255),
      context: context,
      builder: (BuildContext builder) {
        return Container(
          color: Colors.transparent,
          height: MediaQuery.of(context).size.height / 3,
          child: Picker(
            backgroundColor: Colors.transparent,
            containerColor: Color.fromARGB(77, 255, 255, 255),
            headerColor: Colors.transparent,
            adapter: PickerDataAdapter<String>(pickerData: _generateWeekList()),
            selecteds: [_getCurrentWeekIndex()],
            changeToFirst: true,
            textAlign: TextAlign.center,
            columnPadding: const EdgeInsets.all(8.0),
            onConfirm: (Picker picker, List value) {
              int selectedIndex = value.first;
              List<String> weekList = _generateWeekList();
              String selectedWeekString = weekList[selectedIndex];
              String yearString = selectedWeekString.split('    :   ')[0];
              String weekStartString = selectedWeekString.split('    :   ')[1].split(' - ')[0];
              List<String> dateParts = weekStartString.split('/');
              int year = int.parse(yearString);
              int month = int.parse(dateParts[0]);
              int day = int.parse(dateParts[1]);
              DateTime newSelectedDay = DateTime(year, month, day);
              setState(() {
                _selectedDay = newSelectedDay;
                initChart(newSelectedDay.subtract(Duration(days: newSelectedDay.weekday - 1)), newSelectedDay.add(Duration(days: 7 - newSelectedDay.weekday)));
              });
              // _getCurrentWeekIndex();
              print('New selected day: $_selectedDay');
            }).makePicker()
        );
      }
    );
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Color.fromARGB(48, 255, 255, 255),
      context: context,
      builder: (BuildContext builder) {
        return Container(
          color: Colors.transparent,
          height: MediaQuery.of(context).size.height / 3,
          child: Picker(
            backgroundColor: Colors.transparent,
            containerColor: Color.fromARGB(77, 255, 255, 255),
            headerColor: Colors.transparent,
            adapter: PickerDataAdapter<String>(pickerData: _generateMonthList()),
            selecteds: [_getCurrentMonthIndex()],
            changeToFirst: true,
            textAlign: TextAlign.center,
            columnPadding: const EdgeInsets.all(8.0),
            onConfirm: (Picker picker, List value) {
              int selectedIndex = value.first;
              List<String> monthList = _generateMonthList();
              String selectedmonthString = monthList[selectedIndex];
              String yearString = selectedmonthString.split('    :   ')[0];
              String monthStartString = selectedmonthString.split('    :   ')[1].split(' - ')[0];
              List<String> dateParts = monthStartString.split('/');
              int year = int.parse(yearString);
              int month = int.parse(dateParts[0]);
              int day = int.parse(dateParts[1]);
              DateTime newSelectedDay = DateTime(year, month, day);
              setState(() {
                _selectedDay = newSelectedDay;
                initChart(DateTime(newSelectedDay.year, newSelectedDay.month, 1), DateTime(newSelectedDay.year, newSelectedDay.month + 1, 1));
              });
              // _getCurrentWeekIndex();
              print('New selected day: $_selectedDay');
            }).makePicker()
        );
      }
    );
  }

  void _showYearPicker(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Color.fromARGB(48, 255, 255, 255),
      context: context,
      builder: (BuildContext builder) {
        return Container(
          color: Colors.transparent,
          height: MediaQuery.of(context).size.height / 3,
          child: Picker(
            backgroundColor: Colors.transparent,
            containerColor: Color.fromARGB(77, 255, 255, 255),
            headerColor: Colors.transparent,
            adapter: PickerDataAdapter<String>(pickerData: _generateYearList()),
            selecteds: [_getCurrentYearIndex()],
            changeToFirst: true,
            textAlign: TextAlign.center,
            columnPadding: const EdgeInsets.all(8.0),
            onConfirm: (Picker picker, List value) {
              int selectedIndex = value.first;
              List<String> yearList = _generateYearList();
              String selectedyearString = yearList[selectedIndex];
              String yearString = selectedyearString.split('    :   ')[0];
              String yearStartString = selectedyearString.split('    :   ')[1].split(' - ')[0];
              List<String> dateParts = yearStartString.split('/');
              int year = int.parse(yearString);
              int month = int.parse(dateParts[0]);
              int day = int.parse(dateParts[1]);
              DateTime newSelectedDay = DateTime(year, month, day);
              setState(() {
                _selectedDay = newSelectedDay;
                initChart(DateTime(newSelectedDay.year, newSelectedDay.month, 1), DateTime(newSelectedDay.year + 1, newSelectedDay.month, 1));
              });
              // _getCurrentWeekIndex();
              print('New selected day: $_selectedDay');
            }).makePicker()
        );
      }
    );
  }

  List<String> _generateWeekList() {
    List<String> weekList = [];
    DateTime now = _selectedDay;
    for (int i = -100; i <= 100; i++) {
      DateTime weekStart = now.subtract(Duration(days: now.weekday - 1)).add(Duration(days: i * 7));
      DateTime weekEnd = weekStart.add(Duration(days: 6));
      
      String weekString = "${weekStart.year.toString().padLeft(2, '0')}    :   ${weekStart.month.toString().padLeft(2, '0')}/${weekStart.day.toString().padLeft(2, '0')} - ${weekEnd.month.toString().padLeft(2, '0')}/${weekEnd.day.toString().padLeft(2, '0')}";
      weekList.add(weekString);
    }
    return weekList;
  }

  void initChart(DateTime startDay, DateTime endDay) async {
    _events = DateRangeItems(
      startDate: startDay,
      endDate: endDay,
      items: [],
    );
    await _events.updateItemsByInterval(startDay, endDay);
    setState(() {});
  }

  List<String> _generateMonthList() {
    List<String> monthList = [];
    DateTime selectedDay = _selectedDay;
    for (int i = -100; i <= 100; i++) {
      final DateTime monthStart = DateTime(selectedDay.year, selectedDay.month + i, 1);
      final DateTime monthEnd = DateTime(selectedDay.year, selectedDay.month + 1 + i, 0);
      String monthString = "${monthStart.year.toString().padLeft(2, '0')}    :   ${monthStart.month.toString().padLeft(2, '0')}/${monthStart.day.toString().padLeft(2, '0')} - ${monthEnd.month.toString().padLeft(2, '0')}/${monthEnd.day.toString().padLeft(2, '0')}";
      monthList.add(monthString);
    }
    return monthList;
  }

  List<String> _generateYearList() {
    List<String> yearList = [];
    DateTime selectedDay = _selectedDay;
    for (int i = -100; i <= 100; i++) {
      final DateTime yearStart = DateTime(selectedDay.year + i, 1, 1);
      final DateTime yearEnd = DateTime(selectedDay.year + i + 1, 1, 0);
      String yearString = "${yearStart.year.toString().padLeft(2, '0')}    :   ${yearStart.month.toString().padLeft(2, '0')}/${yearStart.day.toString().padLeft(2, '0')} - ${yearEnd.month.toString().padLeft(2, '0')}/${yearEnd.day.toString().padLeft(2, '0')}";
      yearList.add(yearString);
    }
    return yearList;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundManager = Provider.of<BackgroundManager>(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(20, 0, 0, 0),
          elevation: 0,
          title: Text('Statistics'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Week'),
              Tab(text: 'Month'),
              Tab(text: 'Year'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () => _showWeekPicker(context),
                      child: Text('Change week', style: TextStyle(color: Colors.blue)),
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.all(Color.fromARGB(130, 65, 172, 255)),
                        backgroundColor: MaterialStateProperty.all(Color.fromARGB(60, 65, 172, 255)),
                        foregroundColor: MaterialStateProperty.all(Colors.blue),
                        shadowColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPieChart(),
                ),
              ],
            ),
            CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () => _showMonthPicker(context),
                      child: Text('Change month', style: TextStyle(color: Colors.blue)),
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.all(Color.fromARGB(130, 65, 172, 255)),
                        backgroundColor: MaterialStateProperty.all(Color.fromARGB(60, 65, 172, 255)),
                        foregroundColor: MaterialStateProperty.all(Colors.blue),
                        shadowColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPieChart(),
                ),
              ],
            ),
            CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: () => _showYearPicker(context),
                      child: Text('Change year', style: TextStyle(color: Colors.blue)),
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.all(Color.fromARGB(130, 65, 172, 255)),
                        backgroundColor: MaterialStateProperty.all(Color.fromARGB(60, 65, 172, 255)),
                        foregroundColor: MaterialStateProperty.all(Colors.blue),
                        shadowColor: MaterialStateProperty.all(Colors.transparent),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPieChart(),
                ),
              ],
            ),
          ],
      
        ),
      ),
    ); 
  }
}
