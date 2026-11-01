import 'package:daily_quest/models/daily_job.dart';
import 'package:daily_quest/screens/calendar_screen.dart';
import 'package:daily_quest/services/database_service.dart';
import 'package:daily_quest/theme/quest_theme.dart';
import 'package:daily_quest/widgets/month_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

class _CalendarDatabase extends DatabaseService {
  _CalendarDatabase() : super.forTest(databasePath: ':memory:');
  final requestedMonths = <DateTime>[];
  final requestedDays = <DateTime>[];

  @override
  Future<Map<String, double>> getMonthlyProgress(DateTime month) async {
    requestedMonths.add(month);
    return {};
  }

  @override
  Future<List<DailyJob>> getDailyJobsForDate(DateTime date) async {
    requestedDays.add(date);
    return [
      for (var id = 1; id <= 20; id++)
        DailyJob(
          date: date.toIso8601String().substring(0, 10),
          jobId: id,
          jobName: '퀘스트 $id',
          categoryName: '건강',
          isCompleted: false,
        ),
    ];
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  Future<void> chooseYear(WidgetTester tester, int year) async {
    await tester.tap(find.byKey(const ValueKey('month-picker-year')));
    await tester.pumpAndSettle();
    final option = find.text('$year년').last;
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
  }

  testWidgets('연월 선택으로 이동하면 달력과 상세 기록이 함께 갱신되고 취소는 유지한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = _CalendarDatabase();
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        home: Scaffold(
          body: CalendarScreen(refreshToken: 0, databaseService: db),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendar-month-picker')));
    await tester.pumpAndSettle();
    await chooseYear(tester, 2020);
    await tester.tap(find.byKey(const ValueKey('month-picker-month-3')));
    await tester.tap(find.text('이동'));
    await tester.pumpAndSettle();

    var calendar = tester.widget<TableCalendar>(find.byType(TableCalendar));
    expect(calendar.focusedDay.year, 2020);
    expect(calendar.focusedDay.month, 3);
    expect(calendar.selectedDayPredicate!(DateTime(2020, 3, 1)), true);
    expect(
      tester.widget<PageView>(find.byType(PageView)).controller!.page,
      2.0,
    );
    expect(db.requestedMonths.last.year, 2020);
    expect(db.requestedMonths.last.month, 3);
    expect(isSameDay(db.requestedDays.last, DateTime(2020, 3, 1)), true);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    calendar = tester.widget<TableCalendar>(find.byType(TableCalendar));
    expect(calendar.focusedDay.month, 4);
    final queryCount = db.requestedDays.length;
    await tester.tap(find.byKey(const ValueKey('calendar-month-picker')));
    await tester.pumpAndSettle();
    await chooseYear(tester, 2021);
    await tester.tap(find.byKey(const ValueKey('month-picker-month-9')));
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    calendar = tester.widget<TableCalendar>(find.byType(TableCalendar));
    expect(calendar.focusedDay.year, 2020);
    expect(calendar.focusedDay.month, 4);
    expect(db.requestedDays.length, queryCount);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면의 연월 선택은 조회 범위 밖의 월을 차단한다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<DateTime>(
                  context: context,
                  builder: (context) => MonthPickerDialog(
                    initialMonth: DateTime(2026, 12),
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2027, 11, 1),
                  ),
                );
              },
              child: const Text('선택'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();
    await chooseYear(tester, 2027);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('month-picker-month-12')),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.text('이동'));
    await tester.tap(find.text('이동'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2027, 11, 1));
    expect(tester.takeException(), isNull);
  });

  for (final offset in [9.0, 85.0]) {
    testWidgets('데이터 교체 후 세로 스크롤 $offset 픽셀이 달력 월로 복원되지 않는다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = _CalendarDatabase();
      var loading = false;
      late StateSetter updateScreen;
      await tester.pumpWidget(
        MaterialApp(
          theme: QuestTheme.data,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateScreen = setState;
                return loading
                    ? const Center(child: CircularProgressIndicator())
                    : CalendarScreen(refreshToken: 0, databaseService: db);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initialCalendar = tester.widget<TableCalendar>(
        find.byType(TableCalendar),
      );
      final expectedPage =
          (initialCalendar.focusedDay.year - initialCalendar.firstDay.year) *
              12 +
          initialCalendar.focusedDay.month -
          initialCalendar.firstDay.month;
      // A previously browsed month must not leak into a newly created screen.
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      final verticalScroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      verticalScroll.position.jumpTo(offset);
      await tester.pumpAndSettle();

      // Mirrors MainScreen removing its tabs while sample data is generated.
      updateScreen(() => loading = true);
      await tester.pump();
      updateScreen(() => loading = false);
      await tester.pumpAndSettle();

      final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(pages.page, expectedPage.toDouble());
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      final previousMonth = DateTime(
        initialCalendar.focusedDay.year,
        initialCalendar.focusedDay.month - 1,
      );
      final calendar = tester.widget<TableCalendar>(find.byType(TableCalendar));
      expect(calendar.focusedDay.year, previousMonth.year);
      expect(calendar.focusedDay.month, previousMonth.month);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('기록 새로고침과 세로 스크롤 후에도 선택한 월·날짜가 유지된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = _CalendarDatabase();
    var refreshToken = 0;
    late StateSetter updateScreen;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateScreen = setState;
              return CalendarScreen(
                refreshToken: refreshToken,
                databaseService: db,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(of: find.byType(TableCalendar), matching: find.text('12'))
          .hitTestable(),
    );
    await tester.pumpAndSettle();
    final selectedCalendar = tester.widget<TableCalendar>(
      find.byType(TableCalendar),
    );
    final selectedDay = DateTime(
      selectedCalendar.focusedDay.year,
      selectedCalendar.focusedDay.month,
      12,
    );
    expect(selectedCalendar.selectedDayPredicate!(selectedDay), true);

    updateScreen(() => refreshToken++);
    await tester.pumpAndSettle();
    final verticalScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    verticalScroll.position.jumpTo(1500);
    await tester.pumpAndSettle();
    // Exercise calendar disposal/recreation by scrolling well past it.
    expect(find.byType(TableCalendar), findsNothing);
    verticalScroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    final restored = tester.widget<TableCalendar>(find.byType(TableCalendar));
    final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
    expect(restored.focusedDay.year, selectedDay.year);
    expect(restored.focusedDay.month, selectedDay.month);
    expect(restored.selectedDayPredicate!(selectedDay), true);
    expect(
      pages.page,
      ((selectedDay.year - restored.firstDay.year) * 12 +
              selectedDay.month -
              restored.firstDay.month)
          .toDouble(),
    );
    expect(tester.takeException(), isNull);
  });
}
