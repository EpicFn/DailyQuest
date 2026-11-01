import 'dart:ui' as ui;

import 'package:daily_quest/theme/quest_theme.dart';
import 'package:daily_quest/widgets/calendar_day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('기록 없음과 0%를 구분하고 100%에만 완료 별을 표시한다', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      for (final progress in <double?>[null, 0, 0.5, 0.99, 1]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: QuestTheme.data,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 42,
                  height: 72,
                  child: CalendarDayCell(
                    day: DateTime(2026, 11, 2),
                    progress: progress,
                    selected: true,
                    today: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final description =
            '11월 2일, 오늘${progress == null ? ', 기록 없음' : ', 달성률 ${(progress * 100).round()}%'}${progress == 1 ? ', 모두 완료' : ''}';
        expect(find.bySemanticsLabel(description), findsOneWidget);
        expect(
          find.byIcon(Icons.star_rounded),
          progress == 1 ? findsOneWidget : findsNothing,
        );
        expect(find.text('오늘'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      // Exact percentages remain available without crowding the date grid.
      await tester.longPress(find.byType(CalendarDayCell));
      await tester.pumpAndSettle();
      expect(find.text('11월 2일, 오늘, 달성률 100%, 모두 완료'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('날짜 숫자의 채워진 영역은 0·25·50·100%에 비례한다', (tester) async {
    final key = GlobalKey();
    final fillPixels = <double, int>{};
    for (final progress in [0.0, 0.25, 0.5, 1.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: QuestTheme.data,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 64,
                  height: 80,
                  child: CalendarDayCell(
                    day: DateTime(2026, 11, 28),
                    progress: progress,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final numberBounds = tester
          .getRect(find.byType(ShaderMask))
          .shift(-tester.getTopLeft(find.byKey(key)));
      final color = (progress == 1 ? QuestTheme.lime : QuestTheme.purple)
          .toARGB32();
      fillPixels[progress] =
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            try {
              final data = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              var pixels = 0;
              for (
                var y = numberBounds.top.ceil();
                y < numberBounds.bottom.floor();
                y++
              ) {
                for (
                  var x = numberBounds.left.ceil();
                  x < numberBounds.right.floor();
                  x++
                ) {
                  final index = (y * image.width + x) * 4;
                  if (data.getUint8(index) == (color >> 16 & 255) &&
                      data.getUint8(index + 1) == (color >> 8 & 255) &&
                      data.getUint8(index + 2) == (color & 255)) {
                    pixels++;
                  }
                }
              }
              return pixels;
            } finally {
              image.dispose();
            }
          }) ??
          0;
    }
    expect(fillPixels[0], 0);
    expect(fillPixels[1], greaterThan(0));
    // Flutter's test font has rectangular glyphs, allowing area comparisons.
    expect(fillPixels[0.25]! / fillPixels[1]!, closeTo(0.25, 0.08));
    expect(fillPixels[0.5]! / fillPixels[1]!, closeTo(0.5, 0.08));
  });
}
