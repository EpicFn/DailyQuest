import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/quest_job.dart';
import '../models/daily_job.dart';
import '../models/quest_backup.dart';

class DatabaseService {
  DatabaseService._() : _testDatabasePath = null, _now = DateTime.now;

  DatabaseService.forTest({
    required String databasePath,
    DateTime Function()? now,
  }) : _testDatabasePath = databasePath,
       _now = now ?? DateTime.now;

  static final instance = DatabaseService._();

  final String? _testDatabasePath;
  final DateTime Function() _now;

  Database? _database;

  String? _lastSyncedDate;
  bool _dailyJobsDirty = true;
  Future<bool>? _pendingSync;

  DateTime get currentTime => _now();
  String get todayKey => _dateKey(_now());

  // --------------------
  // DB 연결
  // --------------------

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath =
        _testDatabasePath ?? join(await getDatabasesPath(), 'daily_quest.db');

    _database = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            is_default INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category_id INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        // 기본 카테고리 생성
        for (final name in ['생활', '건강', '학습', '기타']) {
          await db.insert('categories', {'name': name, 'is_default': 1});
        }

        await _createDailyTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createDailyTables(db);
        }
      },
    );

    return _database!;
  }

  Future<void> close() async {
    await _database?.close();

    _database = null;
    _lastSyncedDate = null;
    _dailyJobsDirty = true;
  }

  // --------------------
  // Daily 테이블 생성
  // --------------------

  Future<void> _createDailyTables(Database db) async {
    await db.execute('''
    CREATE TABLE daily_jobs (
      date TEXT NOT NULL,
      job_id INTEGER NOT NULL,
      job_name TEXT NOT NULL,
      category_name TEXT NOT NULL,
      is_completed INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (date, job_id)
    )
  ''');

    await db.execute('''
    CREATE TABLE daily_state (
      id INTEGER PRIMARY KEY,
      last_date TEXT NOT NULL
    )
  ''');
  }

  // --------------------
  // 날짜 별 동기화
  // --------------------

  Future<bool> ensureDailyJobsSynced() async {
    while (_pendingSync != null) {
      await _pendingSync;
    }
    final pending = _syncIfNeeded();
    _pendingSync = pending;
    try {
      return await pending;
    } finally {
      if (identical(_pendingSync, pending)) _pendingSync = null;
    }
  }

  Future<bool> _syncIfNeeded() async {
    final today = _dateKey(_now());

    // 이미 오늘 동기화했고 변경 사항도 없으면 생략
    if (!_dailyJobsDirty && _lastSyncedDate == today) {
      return false;
    }

    await syncDailyJobs();

    _lastSyncedDate = today;
    _dailyJobsDirty = false;

    return true;
  }

  Future<void> syncDailyJobs() async {
    final db = await database;

    final now = _now();
    final today = _dateKey(now);
    final currentDay = DateTime(now.year, now.month, now.day);

    // 현재 활성화된 Job 조회
    final activeJobs = await db.rawQuery('''
    SELECT
      j.id AS job_id,
      j.name AS job_name,
      COALESCE(c.name, '기타') AS category_name
    FROM jobs j
    LEFT JOIN categories c ON j.category_id = c.id
    WHERE j.is_active = 1
    ORDER BY j.id
  ''');

    await db.transaction((txn) async {
      // 마지막 기록 생성 날짜 조회
      final state = await txn.query(
        'daily_state',
        where: 'id = ?',
        whereArgs: [1],
      );

      final lastDate = state.isEmpty
          ? null
          : state.first['last_date'] as String;

      // 앱을 실행하지 않은 날짜의 기록 생성
      if (lastDate != null) {
        var day = DateTime.parse(lastDate);

        while (day.isBefore(currentDay)) {
          day = DateTime(day.year, day.month, day.day + 1);

          final date = _dateKey(day);

          for (final job in activeJobs) {
            await txn.insert('daily_jobs', {
              'date': date,
              'job_id': job['job_id'],
              'job_name': job['job_name'],
              'category_name': job['category_name'],
              'is_completed': 0,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }

      // 오늘의 Job 목록 동기화
      final todayRows = await txn.query(
        'daily_jobs',
        columns: ['job_id'],
        where: 'date = ?',
        whereArgs: [today],
      );

      final activeIds = activeJobs.map((job) => job['job_id'] as int).toSet();

      // 오늘 비활성화되거나 삭제된 Job 제거
      for (final row in todayRows) {
        final id = row['job_id'] as int;

        if (!activeIds.contains(id)) {
          await txn.delete(
            'daily_jobs',
            where: 'date = ? AND job_id = ?',
            whereArgs: [today, id],
          );
        }
      }

      // 오늘 활성화된 Job 추가 및 정보 갱신
      for (final job in activeJobs) {
        final id = job['job_id'] as int;

        await txn.insert('daily_jobs', {
          'date': today,
          'job_id': id,
          'job_name': job['job_name'],
          'category_name': job['category_name'],
          'is_completed': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        await txn.update(
          'daily_jobs',
          {'job_name': job['job_name'], 'category_name': job['category_name']},
          where: 'date = ? AND job_id = ?',
          whereArgs: [today, id],
        );
      }

      // 마지막 처리 날짜 저장
      await txn.insert('daily_state', {
        'id': 1,
        'last_date': today,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  // --------------------
  // 오늘 상태 반영
  // --------------------

  Future<List<DailyJob>> getTodayJobs() async {
    await ensureDailyJobsSynced();

    final db = await database;
    final today = _dateKey(_now());

    final rows = await db.query(
      'daily_jobs',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'job_id',
    );

    return rows.map((row) {
      return DailyJob(
        date: row['date'] as String,
        jobId: row['job_id'] as int,
        jobName: row['job_name'] as String,
        categoryName: row['category_name'] as String,
        isCompleted: (row['is_completed'] as int) == 1,
      );
    }).toList();
  }

  Future<bool> setTodayCompleted(
    int jobId,
    bool completed, {
    String? expectedDate,
  }) async {
    await ensureDailyJobsSynced();

    final db = await database;
    final today = _dateKey(_now());

    // A tap from yesterday's still-visible UI must never change today's row.
    if (expectedDate != null && expectedDate != today) return false;

    final count = await db.update(
      'daily_jobs',
      {'is_completed': completed ? 1 : 0},
      where: 'date = ? AND job_id = ?',
      whereArgs: [today, jobId],
    );
    return count > 0;
  }

  Future<String> exportBackup() async {
    await ensureDailyJobsSynced();
    final db = await database;
    return db.transaction((txn) async {
      final state = await txn.query('daily_state', where: 'id = 1');
      final sequences = await txn.query('sqlite_sequence');
      final content = jsonEncode({
        'app': 'daily_quest',
        'version': 1,
        'last_date': state.single['last_date'],
        'categories': await txn.query('categories', orderBy: 'id'),
        'jobs': await txn.query('jobs', orderBy: 'id'),
        'daily_jobs': await txn.query('daily_jobs', orderBy: 'date, job_id'),
        'sequences': {
          'jobs': 0,
          'categories': 4,
          for (final row in sequences)
            if (row['name'] == 'jobs' || row['name'] == 'categories')
              row['name'] as String: row['seq'],
        },
      });
      QuestBackup.parse(content); // Never export a snapshot we cannot restore.
      return content;
    });
  }

  Future<void> restoreBackup(QuestBackup backup) async {
    // Revalidate immediately before mutation, including mutable nested data.
    backup = QuestBackup.parse(jsonEncode(backup.data));
    if (backup.lastDate.compareTo(todayKey) > 0) {
      throw const FormatException('미래 날짜의 백업입니다. 휴대전화 날짜를 확인해 주세요.');
    }
    if (_pendingSync != null) await _pendingSync;
    final db = await database;
    await db.transaction((txn) async {
      for (final table in ['daily_jobs', 'daily_state', 'jobs', 'categories']) {
        await txn.delete(table);
      }
      final batch = txn.batch();
      for (final table in ['categories', 'jobs', 'daily_jobs']) {
        for (final row in backup.rows(table)) {
          batch.insert(table, row);
        }
      }
      batch.insert('daily_state', {'id': 1, 'last_date': backup.lastDate});
      await batch.commit(noResult: true);
      for (final table in ['jobs', 'categories']) {
        await txn.delete(
          'sqlite_sequence',
          where: 'name = ?',
          whereArgs: [table],
        );
        await txn.insert('sqlite_sequence', {
          'name': table,
          'seq': (backup.data['sequences'] as Map)[table],
        });
      }
    });
    _lastSyncedDate = null;
    _dailyJobsDirty = true;
  }

  // --------------------
  // Job CRUD
  // --------------------

  Future<List<QuestJob>> getJobs() async {
    final db = await database;
    final rows = await db.query('jobs', orderBy: 'id');

    return rows.map((row) {
      return QuestJob(
        id: row['id'] as int,
        name: row['name'] as String,
        categoryId: row['category_id'] as int,
        isActive: (row['is_active'] as int) == 1,
      );
    }).toList();
  }

  Future<void> addJob(String name, int categoryId) async {
    await ensureDailyJobsSynced();

    final db = await database;

    await db.insert('jobs', {
      'name': name,
      'category_id': categoryId,
      'is_active': 1,
    });

    // 변경 후 오늘 기록 갱신
    _dailyJobsDirty = true;
    await ensureDailyJobsSynced();
  }

  Future<void> updateJob(int id, String name, int categoryId) async {
    await ensureDailyJobsSynced();

    final db = await database;

    await db.update(
      'jobs',
      {'name': name, 'category_id': categoryId},
      where: 'id = ?',
      whereArgs: [id],
    );

    _dailyJobsDirty = true;
    await ensureDailyJobsSynced();
  }

  Future<void> deleteJob(int id) async {
    await ensureDailyJobsSynced();

    final db = await database;

    await db.delete('jobs', where: 'id = ?', whereArgs: [id]);

    _dailyJobsDirty = true;
    await ensureDailyJobsSynced();
  }

  Future<void> toggleJob(int id, bool isActive) async {
    await ensureDailyJobsSynced();

    final db = await database;

    await db.update(
      'jobs',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    _dailyJobsDirty = true;
    await ensureDailyJobsSynced();
  }

  // --------------------
  // Category CRUD
  // --------------------

  Future<List<QuestCategory>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'id');

    return rows.map((row) {
      return QuestCategory(
        id: row['id'] as int,
        name: row['name'] as String,
        isDefault: (row['is_default'] as int) == 1,
      );
    }).toList();
  }

  Future<void> addCategory(String name) async {
    await ensureDailyJobsSynced();

    final db = await database;

    await db.insert('categories', {'name': name, 'is_default': 0});
  }

  Future<void> updateCategory(int id, String name) async {
    await ensureDailyJobsSynced();

    final db = await database;

    await db.update(
      'categories',
      {'name': name},
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );

    _dailyJobsDirty = true;
    await ensureDailyJobsSynced();
  }

  Future<void> deleteCategory(int id) async {
    await ensureDailyJobsSynced();

    // 기본 카테고리는 삭제 불가
    if (id <= 4) return;

    final db = await database;

    await db.transaction((txn) async {
      // 소속 Job을 '기타'로 이동
      await txn.update(
        'jobs',
        {'category_id': 4},
        where: 'category_id = ?',
        whereArgs: [id],
      );

      await txn.delete(
        'categories',
        where: 'id = ? AND is_default = 0',
        whereArgs: [id],
      );
    });

    _dailyJobsDirty = true;
    await ensureDailyJobsSynced();
  }

  // --------------------
  // Calandar 조회
  // --------------------

  Future<List<DailyJob>> getDailyJobsForDate(DateTime date) async {
    await ensureDailyJobsSynced();

    final db = await database;
    final dateString = _dateKey(date);

    final rows = await db.query(
      'daily_jobs',
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'job_id',
    );

    return rows.map((row) {
      return DailyJob(
        date: row['date'] as String,
        jobId: row['job_id'] as int,
        jobName: row['job_name'] as String,
        categoryName: row['category_name'] as String,
        isCompleted: (row['is_completed'] as int) == 1,
      );
    }).toList();
  }

  Future<Map<String, double>> getMonthlyProgress(DateTime month) async {
    await ensureDailyJobsSynced();

    final db = await database;

    final startDate = _dateKey(DateTime(month.year, month.month, 1));

    final endDate = _dateKey(DateTime(month.year, month.month + 1, 1));

    final rows = await db.rawQuery(
      '''
    SELECT
      date,
      COUNT(*) AS total,
      SUM(is_completed) AS completed
    FROM daily_jobs
    WHERE date >= ? AND date < ?
    GROUP BY date
  ''',
      [startDate, endDate],
    );

    final Map<String, double> progress = {};

    for (final row in rows) {
      final date = row['date'] as String;
      final total = row['total'] as int;
      final completed = row['completed'] as int;

      progress[date] = total == 0 ? 0.0 : completed / total;
    }

    return progress;
  }

  // --------------------
  // functional
  // --------------------

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
