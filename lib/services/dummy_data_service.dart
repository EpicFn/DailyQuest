import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

/// Explicitly replaces local data. Only exposed by the debug menu after consent.
class DummyDataService {
  DummyDataService({DatabaseService? databaseService, DateTime Function()? now})
    : _service = databaseService ?? DatabaseService.instance,
      _now = now ?? DateTime.now;

  final DatabaseService _service;
  final DateTime Function() _now;

  Future<void> replaceWithSampleData() async {
    _requireDebug();
    final db = await _service.database;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);

    await db.transaction((txn) async {
      await _clear(txn, today);
      final personalCategory = await txn.insert('categories', {
        'name': '자기계발',
        'is_default': 0,
      });
      final samples = [
        (name: '물 8잔 마시기', category: 2, label: '건강', active: true),
        (name: '30분 산책하기', category: 2, label: '건강', active: true),
        (name: '책 20쪽 읽기', category: 3, label: '학습', active: true),
        (name: '영어 단어 복습', category: 3, label: '학습', active: true),
        (name: '내 공간 정리하기', category: 1, label: '생활', active: true),
        (
          name: '감사 일기 쓰기',
          category: personalCategory,
          label: '자기계발',
          active: true,
        ),
        (name: '10분 명상하기', category: 4, label: '기타', active: false),
      ];
      final ids = <int>[];
      for (final sample in samples) {
        ids.add(
          await txn.insert('jobs', {
            'name': sample.name,
            'category_id': sample.category,
            'is_active': sample.active ? 1 : 0,
          }),
        );
      }
      // Allocate a real ID before deleting, so future jobs cannot reuse this ID.
      final retiredId = await txn.insert('jobs', {
        'name': '아침 스트레칭',
        'category_id': 2,
        'is_active': 1,
      });
      await txn.delete('jobs', where: 'id = ?', whereArgs: [retiredId]);

      final batch = txn.batch();
      for (var ago = 89; ago >= 0; ago--) {
        final date = _dateKey(
          DateTime(today.year, today.month, today.day - ago),
        );
        final entries = <({int id, String name, String category})>[];
        for (var index = 0; index < samples.length; index++) {
          final sample = samples[index];
          if (!sample.active && ago < 14) continue;
          entries.add((
            id: ids[index],
            name: index == 2 && ago > 45 ? '독서하기' : sample.name,
            category: index == 5 && ago > 30 ? '취미' : sample.label,
          ));
        }
        if (ago >= 20) {
          entries.add((id: retiredId, name: '아침 스트레칭', category: '건강'));
        }
        final completed = ago == 0 ? 2 : (ago * 7 + 3) % (entries.length + 1);
        for (var index = 0; index < entries.length; index++) {
          final entry = entries[index];
          batch.insert('daily_jobs', {
            'date': date,
            'job_id': entry.id,
            'job_name': entry.name,
            'category_name': entry.category,
            'is_completed': index < completed ? 1 : 0,
          });
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> resetAllData() async {
    _requireDebug();
    final db = await _service.database;
    await db.transaction((txn) => _clear(txn, _now()));
  }

  Future<void> _clear(Transaction txn, DateTime today) async {
    for (final table in ['daily_jobs', 'daily_state', 'jobs', 'categories']) {
      await txn.delete(table);
    }
    final defaults = ['생활', '건강', '학습', '기타'];
    for (var index = 0; index < defaults.length; index++) {
      await txn.insert('categories', {
        'id': index + 1,
        'name': defaults[index],
        'is_default': 1,
      });
    }
    await txn.insert('daily_state', {'id': 1, 'last_date': _dateKey(today)});
  }

  void _requireDebug() {
    if (!kDebugMode) throw StateError('개발용 데이터는 디버그 모드에서만 사용할 수 있습니다.');
  }

  String _dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
