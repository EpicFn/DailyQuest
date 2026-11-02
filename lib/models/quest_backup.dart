import 'dart:convert';

/// A portable, validated snapshot. SQL and platform paths are never imported.
class QuestBackup {
  QuestBackup._(this.data);

  static const maxBytes = 10 * 1024 * 1024;
  final Map<String, dynamic> data;

  String get lastDate => data['last_date'] as String;
  List<Map<String, Object?>> rows(String table) =>
      (data[table] as List).cast<Map<String, Object?>>();

  factory QuestBackup.parse(String source) {
    if (utf8.encode(source).length > maxBytes) {
      throw const FormatException('백업 파일은 10MB 이하만 지원합니다.');
    }
    try {
      final raw = jsonDecode(source);
      if (raw is! Map<String, dynamic> ||
          raw['app'] != 'daily_quest' ||
          raw['version'] != 1) {
        throw const FormatException();
      }
      final lastDate = _date(raw['last_date']);
      final tables = <String, List<Map<String, Object?>>>{};
      final categoryIds = <int>{};
      final jobIds = <int>{};
      final historyIds = <String>{};
      for (final table in ['categories', 'jobs', 'daily_jobs']) {
        final input = raw[table];
        if (input is! List || input.length > 100000) {
          throw const FormatException();
        }
        tables[table] = input.map((item) {
          if (item is! Map) throw const FormatException();
          if (table == 'categories') {
            final id = _id(item['id']);
            if (!categoryIds.add(id)) throw const FormatException();
            return <String, Object?>{
              'id': id,
              'name': _name(item['name']),
              'is_default': _bit(item['is_default']),
            };
          }
          if (table == 'jobs') {
            final id = _id(item['id']);
            final categoryId = _id(item['category_id']);
            if (!jobIds.add(id) || !categoryIds.contains(categoryId)) {
              throw const FormatException();
            }
            return <String, Object?>{
              'id': id,
              'name': _name(item['name']),
              'category_id': categoryId,
              'is_active': _bit(item['is_active']),
            };
          }
          final date = _date(item['date']);
          final id = _id(item['job_id']);
          if (date.compareTo(lastDate) > 0 || !historyIds.add('$date/$id')) {
            throw const FormatException();
          }
          // Deleted jobs legitimately remain in historical snapshots.
          return <String, Object?>{
            'date': date,
            'job_id': id,
            'job_name': _name(item['job_name']),
            'category_name': _name(item['category_name']),
            'is_completed': _bit(item['is_completed']),
          };
        }).toList();
      }
      const defaults = ['생활', '건강', '학습', '기타'];
      for (var i = 0; i < defaults.length; i++) {
        final category = tables['categories']!.where(
          (row) => row['id'] == i + 1,
        );
        if (category.length != 1 ||
            category.single['name'] != defaults[i] ||
            category.single['is_default'] != 1) {
          throw const FormatException();
        }
      }
      if (tables['categories']!.any(
        (row) => (row['id'] as int) > 4 && row['is_default'] != 0,
      )) {
        throw const FormatException();
      }
      final sequences = raw['sequences'];
      if (sequences is! Map) throw const FormatException();
      final jobSequence = _id(sequences['jobs'], allowZero: true);
      final categorySequence = _id(sequences['categories']);
      if (jobIds.any((id) => id > jobSequence) ||
          tables['daily_jobs']!.any(
            (row) => (row['job_id'] as int) > jobSequence,
          ) ||
          categoryIds.any((id) => id > categorySequence)) {
        throw const FormatException();
      }
      return QuestBackup._({
        'app': 'daily_quest',
        'version': 1,
        'last_date': lastDate,
        ...tables,
        'sequences': {'jobs': jobSequence, 'categories': categorySequence},
      });
    } on FormatException {
      throw const FormatException('지원하지 않거나 손상된 데일리퀘스트 백업입니다.');
    }
  }

  static int _id(dynamic value, {bool allowZero = false}) {
    if (value is! int || value < (allowZero ? 0 : 1) || value > 2147483647) {
      throw const FormatException();
    }
    return value;
  }

  static int _bit(dynamic value) {
    if (value is! int || (value != 0 && value != 1)) {
      throw const FormatException();
    }
    return value;
  }

  static String _name(dynamic value) {
    if (value is! String || value.trim().isEmpty || value.length > 10000) {
      throw const FormatException();
    }
    return value;
  }

  static String _date(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException();
    }
    final day = DateTime.tryParse(value);
    if (day == null ||
        day.toIso8601String().substring(0, 10) != value ||
        day.year < 2020 ||
        day.year > 2100) {
      throw const FormatException();
    }
    return value;
  }
}
