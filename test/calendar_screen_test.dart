import 'package:daily_quest/models/daily_job.dart';
import 'package:daily_quest/screens/calendar_screen.dart';
import 'package:daily_quest/services/database_service.dart';
import 'package:daily_quest/theme/quest_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

class _CalendarDatabase extends DatabaseService {
  _CalendarDatabase() : super.forTest(databasePath: ':memory:');

  @override
  Future<Map<String, double>> getMonthlyProgress(DateTime month) async => {};

  @override
  Future<List<DailyJob>> getDailyJobsForDate(DateTime date) async => [
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

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

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
