import 'package:daily_quest/models/category.dart';
import 'package:daily_quest/models/daily_job.dart';
import 'package:daily_quest/models/quest_job.dart';
import 'package:daily_quest/screens/main_screen.dart';
import 'package:daily_quest/screens/manage_screen.dart';
import 'package:daily_quest/screens/today_screen.dart';
import 'package:daily_quest/services/database_service.dart';
import 'package:daily_quest/theme/quest_theme.dart';
import 'package:daily_quest/widgets/job_tile.dart';
import 'package:daily_quest/widgets/quest_widgets.dart';
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
    expect(find.text('모든 도전을 해냈어요!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('오늘 퀘스트는 카테고리별로 모이고 체크 대상은 유지된다', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final jobs = [
      DailyJob(
        date: '2026-11-01',
        jobId: 1,
        jobName: '독서',
        categoryName: '학습',
        isCompleted: false,
      ),
      DailyJob(
        date: '2026-11-01',
        jobId: 2,
        jobName: '산책',
        categoryName: '건강',
        isCompleted: false,
      ),
      DailyJob(
        date: '2026-11-01',
        jobId: 3,
        jobName: '복습',
        categoryName: '학습',
        isCompleted: true,
      ),
    ];
    int? toggledId;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        home: Scaffold(
          body: TodayScreen(
            jobs: jobs,
            categories: [
              QuestCategory(id: 2, name: '건강'),
              QuestCategory(id: 3, name: '학습'),
            ],
            onToggleCompleted: (id, value) => toggledId = id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<DailyQuestTile>(find.byType(DailyQuestTile))
          .map((tile) => tile.job.jobName),
      ['산책', '독서', '복습'],
    );
    expect(find.text('1개'), findsOneWidget);
    expect(find.text('2개'), findsOneWidget);
    expect(find.text('완료 1 / 3'), findsOneWidget);
    await tester.tap(find.text('독서'));
    expect(toggledId, 1);
    expect(jobs.map((job) => job.jobId), [1, 2, 3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('관리 필터는 전체·개별·빈 카테고리를 표시하고 선택한 분류로 추가한다', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var categories = [
      QuestCategory(id: 2, name: '건강'),
      QuestCategory(id: 3, name: '학습'),
      QuestCategory(id: 5, name: '취미'),
    ];
    final jobs = [
      QuestJob(id: 1, name: '독서', categoryId: 3, isActive: false),
      QuestJob(id: 2, name: '산책', categoryId: 2),
      QuestJob(id: 3, name: '복습', categoryId: 3),
    ];
    late StateSetter updateScreen;
    int? addedCategory;
    int? toggledId;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateScreen = setState;
              return ManageScreen(
                jobs: jobs,
                categories: categories,
                onAddJob: (name, category) => addedCategory = category,
                onUpdateJob: (_, _, _) {},
                onDeleteJob: (_) {},
                onToggleJob: (id, value) => toggledId = id,
                onAddCategory: (_) {},
                onUpdateCategory: (_, _) {},
                onDeleteCategory: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    List<String> visibleNames() => tester
        .widgetList<JobTile>(find.byType(JobTile))
        .map((tile) => tile.job.name)
        .toList();
    expect(visibleNames(), ['산책', '독서', '복습']);

    await tester.tap(find.byKey(const ValueKey('category-filter-active')));
    await tester.pumpAndSettle();
    expect(visibleNames(), ['산책', '복습']);
    updateScreen(() {
      jobs[1].isActive = false;
      jobs[2].isActive = false;
    });
    await tester.pumpAndSettle();
    expect(visibleNames(), isEmpty);
    expect(find.text('진행 중인 퀘스트가 없어요'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('category-filter-all')));
    await tester.pumpAndSettle();
    expect(visibleNames(), ['산책', '독서', '복습']);
    updateScreen(() {
      jobs[1].isActive = true;
      jobs[2].isActive = true;
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('category-filter-3')));
    await tester.pumpAndSettle();
    expect(visibleNames(), ['독서', '복습']);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey(1)),
        matching: find.byType(Switch),
      ),
    );
    expect(toggledId, 1);
    await tester.tap(find.widgetWithText(FilledButton, '추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '영어 공부');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(addedCategory, 3);

    updateScreen(
      () => categories = [
        categories.first,
        QuestCategory(id: 3, name: '공부'),
        categories.last,
      ],
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('category-filter-3')))
          .selected,
      true,
    );
    expect(visibleNames(), ['독서', '복습']);

    await tester.tap(find.byKey(const ValueKey('category-filter-5')));
    await tester.pumpAndSettle();
    expect(visibleNames(), isEmpty);
    expect(find.text('이 카테고리에 퀘스트가 없어요'), findsOneWidget);
    updateScreen(
      () => categories = categories
          .where((category) => category.id != 5)
          .toList(),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('category-filter-all')))
          .selected,
      true,
    );
    expect(visibleNames(), ['산책', '독서', '복습']);

    await tester.tap(find.byKey(const ValueKey('category-filter-2')));
    await tester.pumpAndSettle();
    expect(visibleNames(), ['산책']);
    await tester.tap(find.byKey(const ValueKey('category-filter-all')));
    await tester.pumpAndSettle();
    expect(visibleNames(), ['산책', '독서', '복습']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('필터 끝에서 카테고리를 추가하고 별도 버튼으로 수정·삭제한다', (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var categories = [QuestCategory(id: 2, name: '건강', isDefault: true)];
    int? deletedId;
    await tester.pumpWidget(
      MaterialApp(
        theme: QuestTheme.data,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ManageScreen(
              jobs: const [],
              categories: categories,
              onAddJob: (_, _) {},
              onUpdateJob: (_, _, _) {},
              onDeleteJob: (_) {},
              onToggleJob: (_, _) {},
              onAddCategory: (name) => setState(() {
                categories = [...categories, QuestCategory(id: 5, name: name)];
              }),
              onUpdateCategory: (id, name) => setState(() {
                categories = categories
                    .map(
                      (category) => category.id == id
                          ? QuestCategory(id: id, name: name)
                          : category,
                    )
                    .toList();
              }),
              onDeleteCategory: (id) => setState(() {
                deletedId = id;
                categories = categories
                    .where((category) => category.id != id)
                    .toList();
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-filter-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-selected-category')), findsNothing);
    expect(
      find.byKey(const ValueKey('delete-selected-category')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('카테고리 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '취미');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-filter-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-selected-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '창작');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('창작 0'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('category-filter-5')))
          .selected,
      true,
    );

    await tester.tap(find.byKey(const ValueKey('delete-selected-category')));
    await tester.pumpAndSettle();
    expect(find.textContaining('기타로 이동합니다.'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(deletedId, isNull);
    await tester.tap(find.byKey(const ValueKey('delete-selected-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();
    expect(deletedId, 5);
    expect(find.byKey(const ValueKey('category-filter-5')), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('category-filter-all')))
          .selected,
      true,
    );
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
