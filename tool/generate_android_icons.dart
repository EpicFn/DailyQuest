// Asset generator using Flutter's renderer; run from the project root:
// flutter test tool/generate_android_icons.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const res = 'android/app/src/main/res';
const purple = Color(0xFF7041CD);
// Vector adaptation of assets/branding/scroll-icon-reference.png.
const scrollData =
    'M30,19 L71,19 C77,19 80,23 80,29 L80,74 '
    'C75,74 73,78 73,82 C73,86 77,88 81,87 '
    'C75,87 75,77 78,76 L82,76 C88,76 89,80 89,84 '
    'C89,89 85,91 80,91 L44,91 C36,91 32,86 32,78 '
    'L32,39 C37,33 38,28 34,24 C31,20 28,20 26,22 '
    'C33,22 34,27 33,32 C33,34 32,34 30,34 '
    'L26,34 C21,34 20,32 20,28 C20,23 25,19 30,19 Z';
const checkData =
    'M41.6,52.5 C40,51 40,48.5 41.6,47 '
    'C43.1,45.5 45.5,45.5 47,47 L52,52 L66.5,37.5 '
    'C68,36 70.5,36 72,37.5 C73.5,39 73.5,41.5 72,43 '
    'L54.8,60.2 C53.2,61.8 50.8,61.8 49.2,60.2 Z';
const lineData =
    'M45,66.5 L68,66.5 C71.8,66.5 71.8,71.5 68,71.5 '
    'L45,71.5 C41.2,71.5 41.2,66.5 45,66.5 Z';
const iconData = '$scrollData $checkData $lineData';

// These paths deliberately stay inside the adaptive icon's central safe area.
Path path(String data) {
  final tokens = RegExp(r'[MLCZ]|-?\d+(?:\.\d+)?')
      .allMatches(data)
      .map((m) => m[0]!)
      .toList();
  final result = Path();
  var index = 0;
  double number() => double.parse(tokens[index++]);
  while (index < tokens.length) {
    switch (tokens[index++]) {
      case 'M':
        result.moveTo(number(), number());
      case 'L':
        result.lineTo(number(), number());
      case 'C':
        result.cubicTo(
          number(),
          number(),
          number(),
          number(),
          number(),
          number(),
        );
      case 'Z':
        result.close();
      default:
        throw FormatException('Unsupported icon path');
    }
  }
  return result;
}

Future<void> write(String name, String content) async {
  final file = File('$res/$name');
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

String vector(String paths) =>
    '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
$paths
</vector>
''';

void main() {
  test('Generate Android launcher assets', () async {
    final foreground = vector(
      '''    <group android:pivotX="54" android:pivotY="54" android:scaleX="0.70" android:scaleY="0.70">
        <path android:fillColor="#FFFFFF" android:fillType="evenOdd"
            android:pathData="$iconData" />
    </group>''',
    );
    await write('drawable/ic_quest_foreground.xml', foreground);
    await write('drawable/ic_quest_monochrome.xml', foreground);
    await write(
      'values/icon_colors.xml',
      '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="quest_icon_background">#7041CD</color>
</resources>
''',
    );
    for (final version in [26, 33]) {
      await write(
        'mipmap-anydpi-v$version/ic_launcher.xml',
        '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/quest_icon_background" />
    <foreground android:drawable="@drawable/ic_quest_foreground" />
${version == 33 ? '    <monochrome android:drawable="@drawable/ic_quest_monochrome" />\n' : ''}</adaptive-icon>
''',
      );
    }
    final outputs = <String, int>{
      for (final entry in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries)
        '$res/mipmap-${entry.key}/ic_launcher.png': entry.value,
      'build/ui-previews/app-icon.png': 512,
    };
    for (final entry in outputs.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(entry.value / 108);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 2, 104, 104),
          const Radius.circular(24),
        ),
        Paint()..color = purple,
      );
      // Legacy icons have no launcher crop, so enlarge the foreground to match.
      canvas.translate(54, 54);
      canvas.scale(0.95);
      canvas.translate(-54, -54);
      canvas.drawPath(
        path(iconData)..fillType = PathFillType.evenOdd,
        Paint()..color = const Color(0xFFFFFFFF),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(entry.value, entry.value);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File(entry.key);
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }
  });
}
