import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/daily_job.dart';
import '../services/database_service.dart';

class CalendarScreen extends StatefulWidget {
  final int refreshToken;

  const CalendarScreen({super.key, required this.refreshToken});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final db = DatabaseService.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<String, double> _monthlyProgress = {};
  List<DailyJob> _selectedJobs = [];

  bool _loadingDay = true;

  int _monthRequestId = 0;
  int _dayRequestId = 0;

  @override
  void initState() {
    super.initState();

    _loadMonth();
    _loadSelectedDay();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadMonth();
      _loadSelectedDay();
    }
  }

  // 날짜를 YYYY-MM-DD 문자열로 변환
  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // 현재 표시 중인 월의 달성률 조회
  Future<void> _loadMonth() async {
    final requestId = ++_monthRequestId;

    final progress = await db.getMonthlyProgress(_focusedDay);

    if (!mounted || requestId != _monthRequestId) return;

    setState(() {
      _monthlyProgress = progress;
    });
  }

  // 선택한 날짜의 퀘스트 조회
  Future<void> _loadSelectedDay() async {
    final requestId = ++_dayRequestId;

    final jobs = await db.getDailyJobsForDate(_selectedDay);

    if (!mounted || requestId != _dayRequestId) return;

    setState(() {
      _selectedJobs = jobs;
      _loadingDay = false;
    });
  }

  // 날짜 선택
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final monthChanged =
        _focusedDay.year != focusedDay.year ||
        _focusedDay.month != focusedDay.month;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _loadingDay = true;
    });

    if (monthChanged) {
      _loadMonth();
    }

    _loadSelectedDay();
  }

  // 월 변경
  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      _selectedDay = DateTime(focusedDay.year, focusedDay.month, 1);
      _loadingDay = true;
    });

    _loadMonth();
    _loadSelectedDay();
  }

  // 날짜별 달성률 표시 Widget
  Widget _buildDayCell(
    DateTime day, {
    bool selected = false,
    bool today = false,
  }) {
    final progress = _monthlyProgress[_dateKey(day)];

    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = selected
        ? colorScheme.primary
        : today
        ? colorScheme.primaryContainer
        : Colors.transparent;

    final textColor = selected ? colorScheme.onPrimary : colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: selected || today
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),

          if (progress != null)
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? colorScheme.onPrimary
                    : progress == 1.0
                    ? Colors.green
                    : colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  // 선택 날짜의 상세 기록
  Widget _buildDailyDetails() {
    if (_loadingDay) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedJobs.isEmpty) {
      return const Center(child: Text('해당 날짜의 퀘스트 기록이 없습니다.'));
    }

    final completed = _selectedJobs.where((job) => job.isCompleted).length;

    final total = _selectedJobs.length;
    final progress = (completed / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '완료 $completed / $total ($progress%)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _selectedJobs.length,
            itemBuilder: (context, index) {
              final job = _selectedJobs[index];

              return ListTile(
                leading: Icon(
                  job.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: job.isCompleted ? Colors.green : Colors.grey,
                ),

                title: Text(
                  job.jobName,
                  style: TextStyle(
                    decoration: job.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),

                subtitle: Text(job.categoryName),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          locale: 'ko_KR',

          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),

          focusedDay: _focusedDay,

          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },

          onDaySelected: _onDaySelected,
          onPageChanged: _onPageChanged,

          calendarFormat: CalendarFormat.month,

          startingDayOfWeek: StartingDayOfWeek.sunday,

          rowHeight: 54,

          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),

          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildDayCell(day);
            },

            todayBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, today: true);
            },

            selectedBuilder: (context, day, focusedDay) {
              return _buildDayCell(day, selected: true);
            },
          ),
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${_selectedDay.year}년 '
            '${_selectedDay.month}월 '
            '${_selectedDay.day}일',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(child: _buildDailyDetails()),
      ],
    );
  }
}
