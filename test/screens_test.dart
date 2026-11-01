import 'package:daily_quest/models/category.dart';
import 'package:daily_quest/models/daily_job.dart';
import 'package:daily_quest/models/quest_job.dart';
import 'package:daily_quest/screens/main_screen.dart';
import 'package:daily_quest/screens/today_screen.dart';
import 'package:daily_quest/services/database_service.dart';
import 'package:daily_quest/theme/quest_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// In-memory UI fixture: screen tests must never open the user's database.
class ScreenDatabase extends DatabaseService {
  ScreenDatabase() : super.forTest(databasePath: ':memory:');
  final today = DateTime.now().toIso8601String().substring(0, 10);
  int writes = 0;
  @override
  Future<List<QuestCategory>> getCategories() async => [
    QuestCategory(id: 2, name: '건강', isDefault: true),
  ];
  @override
  Future<List<QuestJob>> getJobs() async => [
    QuestJob(id: 1, name: '매일 가벼운 스트레칭과 산책으로 건강한 하루 시작하기', categoryId: 2),
  ];
  @override
  Future<List<DailyJob>> getTodayJobs() async => [
    DailyJob(
      date: today,
      jobId: 1,
      jobName: '매일 가벼운 스트레칭과 산책으로 건강한 하루 시작하기',
      categoryName: '건강',
      isCompleted: false,
    ),
  ];
  @override
  Future<List<DailyJob>> getDailyJobsForDate(DateTime date) => getTodayJobs();
  @override
  Future<Map<String, double>> getMonthlyProgress(DateTime month) async => {
    today: 0,
  };
  @override
  Future<void> addJob(String name, int categoryId) async {
    writes++;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  testWidgets('완료 체크는 진행률과 클리어 상태에 반영된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TodayScreen(
              jobs: [
                DailyJob(
                  date: '2026-11-01',
                  jobId: 1,
                  jobName: '물 마시기',
                  categoryName: '건강',
                  isCompleted: completed,
                ),
              ],
              onToggleCompleted: (id, value) =>
                  setState(() => completed = value),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(completed, true);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('오늘의 퀘스트, 클리어!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면과 큰 글자에서도 세 탭과 입력창을 사용할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = ScreenDatabase();
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: MainScreen(databaseService: db),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('관리'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.widgetWithText(FilledButton, '추가'));
    await tester.tap(find.widgetWithText(FilledButton, '추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '새로운 퀘스트');
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(db.writes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('개발용 데이터 교체는 경고 후 취소할 수 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        home: MainScreen(databaseService: ScreenDatabase()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('개발용 데이터'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('90일 샘플 데이터 생성'));
    await tester.pumpAndSettle();
    expect(find.textContaining('되돌릴 수 없습니다.'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
