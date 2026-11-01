import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/quest_job.dart';
import '../models/category.dart';
import '../models/daily_job.dart';

import 'today_screen.dart';
import 'calendar_screen.dart';
import 'manage_screen.dart';

import '../services/database_service.dart';
import '../services/dummy_data_service.dart';
import '../theme/quest_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.databaseService});
  final DatabaseService? databaseService;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  DatabaseService get db => widget.databaseService ?? DatabaseService.instance;

  List<QuestJob> jobs = [];
  List<QuestCategory> categories = [];

  bool loading = true;

  int selectedIndex = 0;

  int calendarRefreshToken = 0;

  List<DailyJob> todayJobs = [];

  final List<String> titles = ['오늘의 도전', '도전 기록', '퀘스트 관리'];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadData();
  }

  // --------------------
  // DB 연결
  // --------------------

  Future<void> loadData() async {
    final loadedCategories = await db.getCategories();
    final loadedJobs = await db.getJobs();
    final loadedTodayJobs = await db.getTodayJobs();

    if (!mounted) return;

    setState(() {
      categories = loadedCategories;
      jobs = loadedJobs;
      todayJobs = loadedTodayJobs;
      loading = false;
      calendarRefreshToken++;
    });
  }

  // --------------------
  // 앱 복귀 이벤트 처리
  // --------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !loading) {
      checkDailySync();
    }
  }

  Future<void> checkDailySync() async {
    final synced = await db.ensureDailyJobsSynced();

    if (synced && mounted) {
      await loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --------------------
  // Job 관리
  // --------------------

  Future<void> addJob(String name, int categoryId) async {
    await db.addJob(name, categoryId);
    await loadData();
  }

  Future<void> updateJob(int id, String name, int categoryId) async {
    await db.updateJob(id, name, categoryId);
    await loadData();
  }

  Future<void> deleteJob(int id) async {
    await db.deleteJob(id);
    await loadData();
  }

  Future<void> toggleJob(int id, bool isActive) async {
    await db.toggleJob(id, isActive);
    await loadData();
  }

  // --------------------
  // Category 관리
  // --------------------

  Future<void> addCategory(String name) async {
    await db.addCategory(name);
    await loadData();
  }

  Future<void> updateCategory(int id, String name) async {
    await db.updateCategory(id, name);
    await loadData();
  }

  Future<void> deleteCategory(int id) async {
    await db.deleteCategory(id);
    await loadData();
  }

  // --------------------
  // 토글
  // --------------------

  Future<void> toggleCompleted(int jobId, bool completed) async {
    await db.setTodayCompleted(jobId, completed);
    await loadData();
  }

  // --------------------
  // 화면 빌드
  // --------------------

  Future<void> showDeveloperAction(String action) async {
    if (!kDebugMode || loading) return;
    final generate = action == 'sample';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(generate ? '90일 샘플 데이터 생성' : '전체 데이터 초기화'),
        content: Text(
          generate
              ? '기존 퀘스트, 카테고리, 모든 날짜의 기록을 삭제하고 최근 90일의 샘플로 교체합니다. 이 작업은 되돌릴 수 없습니다.'
              : '샘플뿐 아니라 직접 입력한 퀘스트와 모든 기록도 삭제합니다. 기본 카테고리만 남으며 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(generate ? '삭제 후 생성' : '모두 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => loading = true);
    try {
      final dummy = DummyDataService(databaseService: db);
      if (generate) {
        await dummy.replaceWithSampleData();
      } else {
        await dummy.resetAllData();
      }
      await loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(generate ? '90일 샘플 데이터를 생성했어요.' : '데이터를 초기화했어요.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터 작업을 완료하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF38265F),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: QuestTheme.purple,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DAILY QUEST',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: QuestTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    titles[selectedIndex],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (kDebugMode)
            PopupMenuButton<String>(
              tooltip: '개발용 데이터',
              enabled: !loading,
              icon: const Icon(Icons.science_outlined, color: QuestTheme.muted),
              onSelected: showDeveloperAction,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'sample', child: Text('90일 샘플 데이터 생성')),
                PopupMenuItem(value: 'reset', child: Text('전체 데이터 초기화')),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: IndexedStack(
                    index: selectedIndex,
                    children: [
                      TodayScreen(
                        jobs: todayJobs,
                        categories: categories,
                        onToggleCompleted: toggleCompleted,
                        onManage: () => setState(() => selectedIndex = 2),
                      ),
                      CalendarScreen(
                        refreshToken: calendarRefreshToken,
                        databaseService: db,
                      ),
                      ManageScreen(
                        jobs: jobs,
                        categories: categories,
                        onAddJob: addJob,
                        onUpdateJob: updateJob,
                        onDeleteJob: deleteJob,
                        onToggleJob: toggleJob,
                        onAddCategory: addCategory,
                        onUpdateCategory: updateCategory,
                        onDeleteCategory: deleteCategory,
                      ),
                    ],
                  ),
                ),
              ),
            ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded),
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '기록',
          ),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: '관리'),
        ],
      ),
    );
  }
}
