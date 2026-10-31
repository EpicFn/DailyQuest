import 'package:flutter/material.dart';

import '../models/quest_job.dart';
import '../models/category.dart';
import '../models/daily_job.dart';

import 'today_screen.dart';
import 'calendar_screen.dart';
import 'manage_screen.dart';

import '../services/database_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final db = DatabaseService.instance;

  List<QuestJob> jobs = [];
  List<QuestCategory> categories = [];

  bool loading = true;

  int selectedIndex = 0;

  int calendarRefreshToken = 0;

  List<DailyJob> todayJobs = [];

  final List<String> titles = ['Today', 'Calendar', 'Manage'];

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
    });

    calendarRefreshToken++;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titles[selectedIndex]), centerTitle: true),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: selectedIndex,
              children: [
                TodayScreen(
                  jobs: todayJobs,
                  onToggleCompleted: toggleCompleted,
                ),
                CalendarScreen(refreshToken: calendarRefreshToken),
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

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Manage'),
        ],
      ),
    );
  }
}
