import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/main_screen.dart';
import 'theme/quest_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko_KR');

  runApp(const DailyQuestApp());
}

class DailyQuestApp extends StatelessWidget {
  const DailyQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '데일리퀘스트',
      debugShowCheckedModeBanner: false,
      theme: QuestTheme.data,
      home: const MainScreen(),
    );
  }
}
