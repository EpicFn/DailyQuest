import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:daily_quest/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;
  late DateTime currentDate;

  // SQLite 테스트 환경 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // 테스트마다 독립적인 DB 생성
  setUp(() {
    currentDate = DateTime(2026, 10, 30);

    db = DatabaseService.forTest(
      databasePath: inMemoryDatabasePath,
      now: () => currentDate,
    );
  });

  // 테스트 종료 시 DB 정리
  tearDown(() async {
    await db.close();
  });

  group('Job 관리', () {
    test('Job 추가 및 조회', () async {
      await db.addJob('운동하기', 2);

      final jobs = await db.getJobs();

      expect(jobs.length, 1);
      expect(jobs.first.name, '운동하기');
      expect(jobs.first.categoryId, 2);
      expect(jobs.first.isActive, true);
    });

    test('Job 수정 및 삭제', () async {
      await db.addJob('운동하기', 2);

      final jobs = await db.getJobs();
      final id = jobs.first.id;

      await db.updateJob(id, '헬스하기', 2);

      var updated = await db.getJobs();

      expect(updated.first.name, '헬스하기');

      await db.deleteJob(id);

      updated = await db.getJobs();

      expect(updated.isEmpty, true);
    });

    test('Job 비활성화', () async {
      await db.addJob('운동하기', 2);

      final job = (await db.getJobs()).first;

      await db.toggleJob(job.id, false);

      final updated = (await db.getJobs()).first;

      expect(updated.isActive, false);

      final todayJobs = await db.getTodayJobs();

      expect(todayJobs.isEmpty, true);
    });
  });

  group('날짜별 퀘스트', () {
    test('완료 상태 저장', () async {
      await db.addJob('운동하기', 2);

      final job = (await db.getJobs()).first;

      await db.setTodayCompleted(job.id, true);

      final todayJobs = await db.getTodayJobs();

      expect(todayJobs.first.isCompleted, true);
    });

    test('날짜 변경 시 완료 상태 초기화', () async {
      await db.addJob('운동하기', 2);

      final job = (await db.getJobs()).first;

      await db.setTodayCompleted(job.id, true);

      // 다음 날로 이동
      currentDate = DateTime(2026, 10, 31);

      final todayJobs = await db.getTodayJobs();

      expect(todayJobs.length, 1);
      expect(todayJobs.first.isCompleted, false);

      // 전날 기록 유지
      final yesterday = await db.getDailyJobsForDate(DateTime(2026, 10, 30));

      expect(yesterday.first.isCompleted, true);
    });

    test('Job 수정 시 과거 기록 불변', () async {
      await db.addJob('운동하기', 2);

      final job = (await db.getJobs()).first;

      // 다음 날로 이동
      currentDate = DateTime(2026, 10, 31);

      await db.updateJob(job.id, '헬스하기', 3);

      // 어제 기록 확인
      final yesterday = await db.getDailyJobsForDate(DateTime(2026, 10, 30));

      expect(yesterday.first.jobName, '운동하기');
      expect(yesterday.first.categoryName, '건강');

      // 오늘 기록 확인
      final today = await db.getTodayJobs();

      expect(today.first.jobName, '헬스하기');
      expect(today.first.categoryName, '학습');
    });

    test('Job 삭제 시 과거 기록 유지', () async {
      await db.addJob('독서하기', 3);

      final job = (await db.getJobs()).first;

      currentDate = DateTime(2026, 10, 31);

      await db.deleteJob(job.id);

      final yesterday = await db.getDailyJobsForDate(DateTime(2026, 10, 30));

      final today = await db.getTodayJobs();

      expect(yesterday.length, 1);
      expect(yesterday.first.jobName, '독서하기');
      expect(today.isEmpty, true);
    });

    test('앱 미실행 날짜의 기록 자동 생성', () async {
      await db.addJob('운동하기', 2);

      // 3일 뒤로 이동
      currentDate = DateTime(2026, 11, 2);

      await db.ensureDailyJobsSynced();

      final october31 = await db.getDailyJobsForDate(DateTime(2026, 10, 31));

      final november1 = await db.getDailyJobsForDate(DateTime(2026, 11, 1));

      expect(october31.length, 1);
      expect(november1.length, 1);

      expect(october31.first.isCompleted, false);
      expect(november1.first.isCompleted, false);
    });
  });

  group('동기화 최적화', () {
    test('같은 날짜에 불필요한 동기화 생략', () async {
      await db.ensureDailyJobsSynced();

      // 이미 동기화된 날짜
      final result = await db.ensureDailyJobsSynced();

      expect(result, false);

      // 날짜 변경
      currentDate = DateTime(2026, 10, 31);

      final changed = await db.ensureDailyJobsSynced();

      expect(changed, true);
    });
  });
}
