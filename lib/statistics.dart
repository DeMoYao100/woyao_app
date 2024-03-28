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
  List<LineChartBarData> lineBarsData = [];
  
  DateRangeItems({
    required this.startDate,
    required this.endDate,
    this.items,
    required this.lineBarsData,
  });

  Future<void> updateItemsByInterval(DateTime startDay, DateTime endDay) async {
    // 用于饼图
    items = await DBProvider.instance.queryEventsByInterval(startDay, endDay);

    // 用于折线图
    Map<String, Map<DateTime, double>> groupedByEvent = {};
    for (var item in items!) {
      final eventDate = parseStartTime(item.startTime);
      final eventDuration = parseDuringTime(item.duringTime);
      // 确保duringTime转换后是有效数字
      if (!eventDuration.isNaN && !eventDuration.isInfinite) {
        groupedByEvent.putIfAbsent(item.name, () => {});
        groupedByEvent[item.name]!.update(eventDate, (value) => value + eventDuration, ifAbsent: () => eventDuration);
      }
    }
    lineBarsData = [];
    int lineIndex = 0; 
    for (var entry in groupedByEvent.entries) {
      final spots = entry.value.entries.map((e) {
        final xValue = e.key.millisecondsSinceEpoch.toDouble();
        final yValue = e.value;
        return FlSpot(xValue, yValue);
      }).toList();
      spots.sort((a, b) => a.x.compareTo(b.x));
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _getSectionColor(lineIndex),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        )
      );
      lineIndex++;
    }
  }
}

class Statistics extends StatefulWidget {
  const Statistics({Key? key}) : super(key: key);
  @override
  State<Statistics> createState() => _StatisticsState();
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

double parseDuringTime(String duringTime) {
  // duringTime转换为小时的小数形式
  List<String> parts = duringTime.split(':');
  double hours = double.parse(parts[0]);
  double minutes = double.parse(parts[1]) / 60.0;
  return hours + minutes;
}

DateTime parseStartTime(String startTime) {
  // 根据实际格式解析startTime字符串为DateTime对象
  return DateFormat('yyyy-MM-dd').parse(startTime);
}

class _StatisticsState extends State<Statistics> {
  late DateTime _selectedDay = DateTime.now();
  late DateRangeItems _events;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _events = DateRangeItems(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      items: [],
      lineBarsData:[],
    );
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

  Widget _buildCustomTextButton({required VoidCallback onPressed, required String buttonText}) {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: TextButton(
          onPressed: () => _showWeekPicker(context),
          child: Text(buttonText, style: TextStyle(color: Colors.blue)),
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(Color.fromARGB(130, 65, 172, 255)),
            backgroundColor: MaterialStateProperty.all(Color.fromARGB(60, 65, 172, 255)),
            foregroundColor: MaterialStateProperty.all(Colors.blue),
            shadowColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ),
      );
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

  Widget _buildLineChart({required int showDay}) {
    return SizedBox(
      height: 250,
      width: 300,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        child: LineChart(
          LineChartData(
            minX: _selectedDay.subtract(Duration(days: showDay)).millisecondsSinceEpoch.toDouble(),
            maxX: _selectedDay.add(Duration(days: showDay)).millisecondsSinceEpoch.toDouble(),
            lineBarsData: _events.lineBarsData ?? [],
            // 配置坐标轴标题
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    final isDateInRange = (date.isAfter(_selectedDay.subtract(Duration(days: showDay))) || date.isAtSameMomentAs(_selectedDay.subtract(Duration(days: showDay)))) &&
                                          (date.isBefore(_selectedDay.add(Duration(days: showDay))) || date.isAtSameMomentAs(_selectedDay.add(Duration(days: showDay))));
                    if (isDateInRange) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(DateFormat('dd').format(date),
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    } else {
                      return Text('');
                    }
                  },
                ),
                
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(enabled: true),
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

  void initChart(DateTime startDay, DateTime endDay) async {
    _events = DateRangeItems(
      startDate: startDay,
      endDate: endDay,
      items: [],
      lineBarsData:[],
    );
    await _events.updateItemsByInterval(startDay, endDay);
    setState(() {});
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
                  child: _buildCustomTextButton(
                    onPressed: () => _showWeekPicker(context), // 传入你的onPressed回调函数
                    buttonText: 'Change week', // 传入按钮上的文本
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPieChart(),
                ),
                SliverToBoxAdapter(
                  child: _buildLineChart(showDay: 4),
                ),
              ],
            ),
            CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _buildCustomTextButton(
                    onPressed: () => _showMonthPicker(context), // 传入你的onPressed回调函数
                    buttonText: 'Change month', // 传入按钮上的文本
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPieChart(),
                ),
                SliverToBoxAdapter(
                  child: _buildLineChart(showDay: 15),
                ),
              ],
            ),
            CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _buildCustomTextButton(
                    onPressed: () => _showYearPicker(context), // 传入你的onPressed回调函数
                    buttonText: 'Change year', // 传入按钮上的文本
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPieChart(),
                ),
                SliverToBoxAdapter(
                  child: _buildLineChart(showDay: 170),
                ),
              ],
            ),
          ],
      
        ),
      ),
    ); 
  }
}
