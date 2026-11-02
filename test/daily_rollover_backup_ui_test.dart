import 'dart:convert';

import 'package:daily_quest/models/daily_job.dart';
import 'package:daily_quest/models/quest_backup.dart';
import 'package:daily_quest/screens/main_screen.dart';
import 'package:daily_quest/screens/today_screen.dart';
import 'package:daily_quest/services/backup_file_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens_test.dart' show ScreenDatabase;

class ClockDatabase extends ScreenDatabase {
  DateTime clock = DateTime(2026, 11, 2, 23, 59, 59);
  int reads = 0;
  int restores = 0;
  final completedDays = <String>{'2026-11-02'};
  @override
  DateTime get currentTime => clock;
  @override
  String get todayKey => clock.toIso8601String().substring(0, 10);
  @override
  Future<bool> ensureDailyJobsSynced() async => false;
  @override
  Future<List<DailyJob>> getTodayJobs() async {
    reads++;
    return [
      DailyJob(
        date: todayKey,
        jobId: 1,
        jobName: '산책',
        categoryName: '건강',
        isCompleted: completedDays.contains(todayKey),
      ),
    ];
  }

  @override
  Future<bool> setTodayCompleted(
    int jobId,
    bool completed, {
    String? expectedDate,
  }) async {
    if (expectedDate != todayKey) return false;
    writes++;
    completed ? completedDays.add(todayKey) : completedDays.remove(todayKey);
    return true;
  }

  @override
  Future<String> exportBackup() async => jsonEncode({
    'app': 'daily_quest',
    'version': 1,
    'last_date': todayKey,
    'categories': [
      for (var i = 0; i < 4; i++)
        {
          'id': i + 1,
          'name': ['생활', '건강', '학습', '기타'][i],
          'is_default': 1,
        },
    ],
    'jobs': [],
    'daily_jobs': [],
    'sequences': {'jobs': 0, 'categories': 4},
  });
  @override
  Future<void> restoreBackup(QuestBackup backup) async {
    restores++;
  }
}

class MemoryBackupFiles extends BackupFileService {
  QuestBackup? selected;
  String? saved;
  bool cancelSave = false;
  @override
  Future<QuestBackup?> pick() async => selected;
  @override
  Future<bool> save(String content) async {
    if (cancelSave) return false;
    saved = content;
    return true;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  Future<void> mount(
    WidgetTester tester,
    ClockDatabase db, {
    MemoryBackupFiles? files,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(databaseService: db, backupFileService: files),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox()));
  }

  Future<void> choose(WidgetTester tester, String action) async {
    await tester.tap(find.byTooltip('백업 및 복원'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  testWidgets('열린 앱이 자정에 새 날짜로 갱신되고 전날 완료 상태는 보존된다', (tester) async {
    final db = ClockDatabase();
    await mount(tester, db);
    expect(
      tester
          .widget<TodayScreen>(find.byType(TodayScreen))
          .jobs
          .single
          .isCompleted,
      true,
    );
    db.clock = DateTime(2026, 11, 3);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final jobs = tester.widget<TodayScreen>(find.byType(TodayScreen)).jobs;
    expect(jobs.single.date, '2026-11-03');
    expect(jobs.single.isCompleted, false);
    expect(db.completedDays, {'2026-11-02'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('며칠 동안 백그라운드에 있다 복귀해도 즉시 날짜를 갱신한다', (tester) async {
    final db = ClockDatabase();
    await mount(tester, db);
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    final reads = db.reads;
    db.clock = DateTime(2026, 11, 5, 9);
    await tester.pump(const Duration(days: 3));
    expect(db.reads, reads);
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TodayScreen>(find.byType(TodayScreen)).jobs.single.date,
      '2026-11-05',
    );
  });

  testWidgets('자정 직전 화면의 콜백은 새 날짜에 완료를 기록하지 않는다', (tester) async {
    final db = ClockDatabase();
    await mount(tester, db);
    final oldScreen = tester.widget<TodayScreen>(find.byType(TodayScreen));
    db.clock = DateTime(2026, 11, 3);
    oldScreen.onToggleCompleted(1, true);
    await tester.pumpAndSettle();
    expect(db.writes, 0);
    expect(db.completedDays.contains('2026-11-03'), false);
    expect(find.text('날짜가 바뀌어 오늘의 퀘스트를 새로 불러왔어요.'), findsOneWidget);
  });

  testWidgets('백업 저장과 파일 선택 취소는 기존 기록을 교체하지 않는다', (tester) async {
    final db = ClockDatabase();
    final files = MemoryBackupFiles();
    await mount(tester, db, files: files);
    await choose(tester, '백업 파일 저장');
    expect(QuestBackup.parse(files.saved!).lastDate, '2026-11-02');
    await choose(tester, '백업 파일 복원');
    expect(find.text('백업을 복원할까요?'), findsNothing);
    expect(db.restores, 0);
  });

  testWidgets('복원은 확인 취소 시 유지하고 승인했을 때만 교체한다', (tester) async {
    final db = ClockDatabase();
    final files = MemoryBackupFiles()
      ..selected = QuestBackup.parse(await db.exportBackup());
    await mount(tester, db, files: files);
    await choose(tester, '백업 파일 복원');
    expect(db.restores, 0);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(db.restores, 0);
    await choose(tester, '백업 파일 복원');
    await tester.tap(find.text('교체하고 복원'));
    await tester.pumpAndSettle();
    expect(db.restores, 1);
    expect(find.text('백업을 복원했어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
