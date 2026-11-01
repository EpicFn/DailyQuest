import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daily_quest/models/quest_job.dart';
import 'package:daily_quest/widgets/job_tile.dart';

void main() {
  testWidgets('JobTile renders job details and forwards actions', (
    WidgetTester tester,
  ) async {
    bool? toggledValue;
    var editCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JobTile(
            job: QuestJob(id: 1, name: '운동하기', categoryId: 2),
            categoryName: '건강',
            onToggle: (value) => toggledValue = value,
            onEdit: () => editCount++,
            onDelete: () => deleteCount++,
          ),
        ),
      ),
    );

    expect(find.text('운동하기'), findsOneWidget);
    expect(find.text('건강'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    expect(toggledValue, false);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    expect(editCount, 1);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(deleteCount, 1);
  });
}
