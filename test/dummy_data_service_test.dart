import 'dart:io';

import 'package:daily_quest/services/database_service.dart';
import 'package:daily_quest/services/dummy_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseService db;
  late DummyDataService dummy;
  late DateTime now;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() {
    now = DateTime(2026, 11, 1);
    db = DatabaseService.forTest(
      databasePath: inMemoryDatabasePath,
      now: () => now,
    );
    dummy = DummyDataService(databaseService: db, now: () => now);
  });
  tearDown(() => db.close());

  test('90일 범위, 다양한 달성률, 이름 변경 및 삭제 이력을 생성한다', () async {
    await dummy.replaceWithSampleData();
    final sql = await db.database;
    final days = await sql.rawQuery(
      'SELECT DISTINCT date FROM daily_jobs ORDER BY date',
    );
    expect(days.length, 90);
    expect(days.first['date'], '2026-08-04');
    expect(days.last['date'], '2026-11-01');
    final jobs = await db.getJobs();
    final today = await db.getTodayJobs();
    expect(
      today.map((job) => job.jobId).toSet(),
      jobs.where((job) => job.isActive).map((job) => job.id).toSet(),
    );
    expect(today.where((job) => job.isCompleted).length, 2);
    final past = await db.getDailyJobsForDate(DateTime(2026, 8, 4));
    expect(past.any((job) => job.jobName == '독서하기'), true);
    expect(today.any((job) => job.jobName == '책 20쪽 읽기'), true);
    expect(past.any((job) => job.categoryName == '취미'), true);
    final deleted = past.singleWhere((job) => job.jobName == '아침 스트레칭');
    expect(jobs.any((job) => job.id == deleted.jobId), false);
    await db.addJob('새로운 퀘스트', 1);
    expect((await db.getJobs()).last.id, greaterThan(deleted.jobId));
    final progress = await db.getMonthlyProgress(DateTime(2026, 8));
    expect(progress.values.toSet().length, greaterThan(3));
    expect(progress.values, containsAll([0.0, 1.0]));
  });

  test('반복 생성과 초기화 후 기본 카테고리와 날짜 동기화가 정상 동작한다', () async {
    await db.addJob('기존 기록', 1);
    await dummy.replaceWithSampleData();
    await dummy.replaceWithSampleData();
    expect((await db.getJobs()).length, 7);
    expect((await db.getCategories()).length, 5);
    await dummy.resetAllData();
    expect(await db.getTodayJobs(), isEmpty);
    expect(await db.getJobs(), isEmpty);
    expect(await db.getDailyJobsForDate(DateTime(2026, 8, 4)), isEmpty);
    expect((await db.getCategories()).map((category) => category.id), [
      1,
      2,
      3,
      4,
    ]);
    await db.addCategory('새 카테고리');
    final category = (await db.getCategories()).last;
    await db.addJob('새 퀘스트', category.id);
    await db.deleteCategory(category.id);
    expect((await db.getTodayJobs()).single.categoryName, '기타');
    now = DateTime(2026, 11, 2);
    expect((await db.getTodayJobs()).single.isCompleted, false);
  });

  test('DB를 다시 열어도 기록이 유지되고 다음 날 완료 상태는 초기화된다', () async {
    final directory = await Directory.systemTemp.createTemp(
      'daily-quest-test-',
    );
    final persistent = DatabaseService.forTest(
      databasePath: '${directory.path}/quest.db',
      now: () => now,
    );
    try {
      await DummyDataService(
        databaseService: persistent,
        now: () => now,
      ).replaceWithSampleData();
      final before = await persistent.getTodayJobs();
      final progressBefore = await persistent.getMonthlyProgress(now);
      await persistent.close();
      expect(
        (await persistent.getTodayJobs()).map((job) => job.isCompleted),
        before.map((job) => job.isCompleted),
      );
      expect(await persistent.getMonthlyProgress(now), progressBefore);
      now = DateTime(2026, 11, 2);
      expect(
        (await persistent.getTodayJobs()).every((job) => !job.isCompleted),
        true,
      );
      final yesterday = await persistent.getDailyJobsForDate(
        DateTime(2026, 11, 1),
      );
      expect(yesterday.where((job) => job.isCompleted).length, 2);
    } finally {
      await persistent.close();
      await directory.delete(recursive: true);
    }
  });
}
