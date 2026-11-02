import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/quest_backup.dart';

class BackupFileService {
  Future<bool> save(String content) async {
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final result = await FilePicker.saveFile(
      fileName: 'daily-quest-$stamp.json',
      bytes: Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
      dialogTitle: '백업 저장',
    );
    return result != null;
  }

  Future<QuestBackup?> pick() async {
    final file = await FilePicker.pickFile(
      dialogTitle: '데일리퀘스트 백업 선택',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return null;
    // Bound the actual read even if the provider reports an incorrect size.
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (bytes.length + chunk.length > QuestBackup.maxBytes) {
        throw const FormatException('백업 파일은 10MB 이하만 지원합니다.');
      }
      bytes.add(chunk);
    }
    return QuestBackup.parse(utf8.decode(bytes.takeBytes()));
  }
}
