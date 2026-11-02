import 'dart:convert';

import 'package:daily_quest/models/quest_backup.dart';
import 'package:daily_quest/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService service;
  var now = DateTime(2026, 11, 2);
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() {
    now = DateTime(2026, 11, 2);
    service = DatabaseService.forTest(
      databasePath: inMemoryDatabasePath,
      now: () => now,
    );
  });
  tearDown(() => service.close());

  test('백업 왕복은 과거 이름·완료 상태·비활성 퀘스트·삭제 ID를 보존한다', () async {
    await service.addCategory('취미');
    await service.addJob('독서', 5);
    await service.addJob('산책', 2);
    await service.setTodayCompleted(1, true);
    now = DateTime(2026, 11, 3);
    await service.updateJob(1, '책 읽기', 3);
    await service.toggleJob(2, false);
    await service.addJob('삭제할 퀘스트', 1);
    await service.deleteJob(3);
    final content = await service.exportBackup();
    await service.deleteJob(1);
    await service.deleteCategory(5);
    await service.restoreBackup(QuestBackup.parse(content));
    expect(jsonDecode(await service.exportBackup()), jsonDecode(content));
    final past = await service.getDailyJobsForDate(DateTime(2026, 11, 2));
    expect(past.first.jobName, '독서');
    expect(past.first.isCompleted, true);
    expect((await service.getJobs())[1].isActive, false);
    await service.addJob('새 퀘스트', 1);
    expect((await service.getJobs()).last.id, greaterThan(3));
  });

  test('빈 백업과 이전 날짜 백업을 복원하고 누락 날짜를 채운다', () async {
    final empty = await service.exportBackup();
    await service.addJob('산책', 2);
    final populated = await service.exportBackup();
    await service.restoreBackup(QuestBackup.parse(empty));
    expect(await service.getJobs(), isEmpty);
    now = DateTime(2026, 11, 4);
    await service.restoreBackup(QuestBackup.parse(populated));
    expect((await service.getTodayJobs()).single.date, '2026-11-04');
    expect(
      (await service.getDailyJobsForDate(DateTime(2026, 11, 3)))
          .single
          .isCompleted,
      false,
    );
  });

  test('변조된 파일은 거부하며 현재 DB를 변경하지 않는다', () async {
    await service.addJob('유지할 퀘스트', 1);
    final original = await service.exportBackup();
    final mutations = <void Function(Map<String, dynamic>)>[
      (data) => data['version'] = 999,
      (data) => data['app'] = 'other',
      (data) => data['categories'] = [],
      (data) => data['jobs'][0]['category_id'] = 999,
      (data) => data['jobs'].add(data['jobs'][0]),
      (data) => data['daily_jobs'][0]['date'] = '2026-02-30',
      (data) => data['daily_jobs'][0]['is_completed'] = true,
      (data) => data['sequences']['jobs'] = 0,
    ];
    for (final mutate in mutations) {
      final data = jsonDecode(original) as Map<String, dynamic>;
      mutate(data);
      expect(() => QuestBackup.parse(jsonEncode(data)), throwsFormatException);
    }
    expect(await service.exportBackup(), original);
  });

  test('복원 도중 SQL 실패 시 삭제까지 전부 롤백한다', () async {
    await service.addJob('백업 퀘스트', 1);
    final backup = QuestBackup.parse(await service.exportBackup());
    await service.updateJob(1, '현재 퀘스트', 2);
    final original = await service.exportBackup();
    final db = await service.database;
    await db.execute(
      "CREATE TRIGGER fail_restore BEFORE INSERT ON jobs BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      service.restoreBackup(backup),
      throwsA(isA<DatabaseException>()),
    );
    expect(await service.exportBackup(), original);
  });

  test('미래 백업은 거부하고 자정 이전 화면의 체크는 새 날짜를 바꾸지 않는다', () async {
    await service.addJob('산책', 2);
    final future = QuestBackup.parse(await service.exportBackup());
    now = DateTime(2026, 11, 1);
    await expectLater(service.restoreBackup(future), throwsFormatException);
    now = DateTime(2026, 11, 3);
    final saved = await service.setTodayCompleted(
      1,
      true,
      expectedDate: '2026-11-02',
    );
    expect(saved, false);
    expect((await service.getTodayJobs()).single.isCompleted, false);
    expect(
      (await service.getDailyJobsForDate(DateTime(2026, 11, 2)))
          .single
          .isCompleted,
      false,
    );
    expect(
      await service.setTodayCompleted(1, true, expectedDate: '2026-11-03'),
      true,
    );
  });
}
