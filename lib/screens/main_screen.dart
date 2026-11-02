import 'dart:async';

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
import '../services/backup_file_service.dart';
import '../theme/quest_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.databaseService, this.backupFileService});
  final DatabaseService? databaseService;
  final BackupFileService? backupFileService;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  DatabaseService get db => widget.databaseService ?? DatabaseService.instance;

  List<QuestJob> jobs = [];
  List<QuestCategory> categories = [];

  bool loading = true;
  bool _busy = false;
  bool _loadFailed = false;
  bool _foreground = true;
  String? _loadedDate;
  Timer? _dailyTimer;

  int selectedIndex = 0;

  int calendarRefreshToken = 0;

  List<DailyJob> todayJobs = [];

  final List<String> titles = ['오늘의 도전', '도전 기록', '퀘스트 관리'];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _runAction(loadData);
    _scheduleDailyCheck();
  }

  // --------------------
  // DB 연결
  // --------------------

  Future<void> loadData() async {
    final requestedDate = db.todayKey;
    final loadedCategories = await db.getCategories();
    final loadedJobs = await db.getJobs();
    final loadedTodayJobs = await db.getTodayJobs();

    if (!mounted) return;

    setState(() {
      categories = loadedCategories;
      jobs = loadedJobs;
      todayJobs = loadedTodayJobs;
      loading = false;
      _loadFailed = false;
      _loadedDate = requestedDate;
      calendarRefreshToken++;
    });
  }

  // --------------------
  // 앱 복귀 이벤트 처리
  // --------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _dailyTimer?.cancel();
    if (_foreground) {
      checkDailySync();
      _scheduleDailyCheck();
    }
  }

  Future<void> checkDailySync() async {
    if (_busy || loading || !mounted) return;
    await _runAction(() async {
      final synced = await db.ensureDailyJobsSynced();
      if (synced || _loadedDate != db.todayKey) await loadData();
    });
  }

  void _scheduleDailyCheck() {
    _dailyTimer?.cancel();
    if (!mounted || !_foreground) return;
    final now = db.currentTime;
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = midnight.difference(now);
    // Re-evaluate the clock at least once a minute, including manual time changes.
    final delay = untilMidnight < const Duration(minutes: 1)
        ? untilMidnight
        : const Duration(minutes: 1);
    _dailyTimer = Timer(delay, () async {
      await checkDailySync();
      _scheduleDailyCheck();
    });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      if (loading) {
        setState(() {
          loading = false;
          _loadFailed = true;
        });
      }
      _message(
        error is FormatException ? error.message : '작업을 완료하지 못했어요. 다시 시도해 주세요.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _dailyTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --------------------
  // Job 관리
  // --------------------

  Future<void> addJob(String name, int categoryId) => _runAction(() async {
    await db.addJob(name, categoryId);
    await loadData();
  });

  Future<void> updateJob(int id, String name, int categoryId) =>
      _runAction(() async {
        await db.updateJob(id, name, categoryId);
        await loadData();
      });

  Future<void> deleteJob(int id) => _runAction(() async {
    await db.deleteJob(id);
    await loadData();
  });

  Future<void> toggleJob(int id, bool isActive) => _runAction(() async {
    await db.toggleJob(id, isActive);
    await loadData();
  });

  // --------------------
  // Category 관리
  // --------------------

  Future<void> addCategory(String name) => _runAction(() async {
    await db.addCategory(name);
    await loadData();
  });

  Future<void> updateCategory(int id, String name) => _runAction(() async {
    await db.updateCategory(id, name);
    await loadData();
  });

  Future<void> deleteCategory(int id) => _runAction(() async {
    await db.deleteCategory(id);
    await loadData();
  });

  // --------------------
  // 토글
  // --------------------

  Future<void> toggleCompleted(
    int jobId,
    bool completed,
    String expectedDate,
  ) => _runAction(() async {
    final saved = await db.setTodayCompleted(
      jobId,
      completed,
      expectedDate: expectedDate,
    );
    await loadData();
    if (!saved) _message('날짜가 바뀌어 오늘의 퀘스트를 새로 불러왔어요.');
  });

  Future<void> _backupAction(String action) => _runAction(() async {
    final files = widget.backupFileService ?? BackupFileService();
    if (action == 'export') {
      final content = await db.exportBackup();
      if (await files.save(content)) _message('백업 파일을 저장했어요.');
      return;
    }
    final backup = await files.pick();
    if (backup == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업을 복원할까요?'),
        content: Text(
          '${backup.lastDate}까지의 기록\n퀘스트 ${backup.rows('jobs').length}개 · 일별 항목 ${backup.rows('daily_jobs').length}개\n\n현재 퀘스트, 카테고리와 모든 기록을 이 백업으로 교체합니다. 현재 기록이 필요하면 먼저 백업해 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('교체하고 복원'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => loading = true);
    await db.restoreBackup(backup);
    await loadData();
    _message('백업을 복원했어요.');
  });

  // --------------------
  // 화면 빌드
  // --------------------

  Future<void> showDeveloperAction(String action) async {
    if (!kDebugMode || loading || _busy) return;
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
    setState(() {
      loading = true;
      _busy = true;
    });
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedJobs = todayJobs;
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
                    '데일리퀘스트',
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
          PopupMenuButton<String>(
            tooltip: '백업 및 복원',
            enabled: !loading && !_busy && !_loadFailed,
            icon: const Icon(Icons.save_outlined),
            onSelected: _backupAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                enabled: false,
                child: Text('백업 파일에는 기록이 그대로 담깁니다.'),
              ),
              PopupMenuItem(value: 'export', child: Text('백업 파일 저장')),
              PopupMenuItem(value: 'import', child: Text('백업 파일 복원')),
            ],
          ),
          if (kDebugMode)
            PopupMenuButton<String>(
              tooltip: '개발용 데이터',
              enabled: !loading && !_busy,
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
          : _loadFailed
          ? Center(
              child: FilledButton(
                onPressed: () => _runAction(loadData),
                child: const Text('다시 불러오기'),
              ),
            )
          : AbsorbPointer(
              absorbing: _busy,
              child: SafeArea(
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
                          onToggleCompleted: (id, completed) => toggleCompleted(
                            id,
                            completed,
                            displayedJobs
                                .firstWhere((job) => job.jobId == id)
                                .date,
                          ),
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
