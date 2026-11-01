import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../theme/quest_theme.dart';
import '../widgets/quest_widgets.dart';

import '../models/daily_job.dart';
import '../services/database_service.dart';

class CalendarScreen extends StatefulWidget {
  final int refreshToken;

  const CalendarScreen({
    super.key,
    required this.refreshToken,
    this.databaseService,
  });
  final DatabaseService? databaseService;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DatabaseService get db => widget.databaseService ?? DatabaseService.instance;

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

  Widget _buildDayCell(
    DateTime day, {
    bool selected = false,
    bool today = false,
  }) {
    final progress = _monthlyProgress[_dateKey(day)];
    return Semantics(
      label:
          '${day.month}월 ${day.day}일${progress == null ? ', 기록 없음' : ', 달성률 ${(progress * 100).round()}%'}',
      selected: selected,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? QuestTheme.purple
              : progress == 1
              ? const Color(0xFF293826)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: today ? Border.all(color: QuestTheme.purple) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: selected ? const Color(0xFF26134E) : null,
                fontWeight: selected || today
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            if (progress != null)
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF26134E)
                      : progress == 1
                      ? QuestTheme.lime
                      : QuestTheme.purple,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = _selectedJobs.where((job) => job.isCompleted).length;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return CustomScrollView(
      key: const PageStorageKey('calendar'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList.list(
            children: [
              Text(
                '매일의 도전이 쌓이는 곳',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '작은 성취도 오래 기억할 수 있도록.',
                style: TextStyle(color: QuestTheme.muted),
              ),
              const SizedBox(height: 24),
              QuestSurface(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                child: Column(
                  children: [
                    TableCalendar(
                      locale: 'ko_KR',
                      firstDay: DateTime(2020, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      onPageChanged: _onPageChanged,
                      calendarFormat: CalendarFormat.month,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      rowHeight: 62 * scale.clamp(1.0, 2.0),
                      daysOfWeekHeight: 28 * scale.clamp(1.0, 2.0),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left_rounded,
                          color: QuestTheme.muted,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right_rounded,
                          color: QuestTheme.muted,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: QuestTheme.muted,
                          fontSize: 12,
                        ),
                        weekendStyle: TextStyle(
                          color: QuestTheme.purple,
                          fontSize: 12,
                        ),
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) =>
                            _buildDayCell(day),
                        todayBuilder: (context, day, focusedDay) =>
                            _buildDayCell(day, today: true),
                        selectedBuilder: (context, day, focusedDay) =>
                            _buildDayCell(day, selected: true),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          '숫자는 그날의 달성률',
                          style: TextStyle(
                            color: QuestTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '● 100% 달성',
                          style: TextStyle(
                            color: QuestTheme.lime,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '○ 오늘',
                          style: TextStyle(
                            color: QuestTheme.purple,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              QuestSectionHeading(
                title: DateFormat('M월 d일 EEEE', 'ko_KR').format(_selectedDay),
                subtitle: _loadingDay
                    ? '기록을 불러오고 있어요'
                    : _selectedJobs.isEmpty
                    ? '이날의 퀘스트 기록'
                    : '완료 $completed / ${_selectedJobs.length} · 달성률 ${(completed / _selectedJobs.length * 100).round()}%',
              ),
              if (_loadingDay)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_selectedJobs.isEmpty)
                const QuestEmptyState(
                  icon: Icons.calendar_today_outlined,
                  title: '아직 기록이 없어요',
                  message: '퀘스트가 기록된 날짜를 선택하면\n그날의 도전과 완료 상태를 볼 수 있어요.',
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList.builder(
            itemCount: _loadingDay ? 0 : _selectedJobs.length,
            itemBuilder: (context, index) =>
                DailyQuestTile(job: _selectedJobs[index]),
          ),
        ),
      ],
    );
  }
}
