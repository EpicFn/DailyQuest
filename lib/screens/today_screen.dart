import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_job.dart';
import '../models/category.dart';
import '../theme/quest_theme.dart';
import '../widgets/quest_widgets.dart';

class TodayScreen extends StatelessWidget {
  final List<DailyJob> jobs;
  final List<QuestCategory> categories;
  final void Function(int, bool) onToggleCompleted;
  final VoidCallback? onManage;

  const TodayScreen({
    super.key,
    required this.jobs,
    this.categories = const [],
    required this.onToggleCompleted,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final completed = jobs.where((job) => job.isCompleted).length;
    final progress = jobs.isEmpty ? 0.0 : completed / jobs.length;
    final allDone = jobs.isNotEmpty && completed == jobs.length;
    final groupedJobs = <String, List<DailyJob>>{};
    for (final job in jobs) {
      groupedJobs.putIfAbsent(job.categoryName, () => []).add(job);
    }
    final categoryOrder = <String>{
      if (categories.isEmpty) ...['생활', '건강', '학습', '기타'],
      ...categories.map((category) => category.name),
      ...groupedJobs.keys,
    }.where(groupedJobs.containsKey);
    final date = jobs.isEmpty
        ? DateTime.now()
        : DateTime.parse(jobs.first.date);
    return CustomScrollView(
      key: const PageStorageKey('today'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList.list(
            children: [
              Text(
                DateFormat('M월 d일 EEEE', 'ko_KR').format(date),
                style: const TextStyle(
                  color: QuestTheme.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7445D8), Color(0xFF432785)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF976DE7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: QuestTheme.lime,
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'DAILY QUEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '오늘의 달성률',
                                style: TextStyle(color: Color(0xFFE5DAFF)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Icon(
                            Icons.emoji_events_outlined,
                            size: 62,
                            color: QuestTheme.lime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: progress),
                      duration: const Duration(milliseconds: 350),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        color: QuestTheme.lime,
                        backgroundColor: const Color(0xFF382062),
                        borderRadius: BorderRadius.circular(8),
                        semanticsLabel: '오늘의 달성률',
                        semanticsValue: '${(progress * 100).round()}%',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          '완료 $completed / ${jobs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          allDone
                              ? '모든 도전을 해냈어요!'
                              : jobs.isEmpty
                              ? '첫 퀘스트를 준비해 볼까요?'
                              : '${jobs.length - completed}개의 도전이 남았어요',
                          style: const TextStyle(color: Color(0xFFE5DAFF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const QuestSectionHeading(
                title: '오늘의 퀘스트',
                subtitle: '스위치로 완료 여부를 선택하세요.',
              ),
              if (jobs.isEmpty)
                QuestEmptyState(
                  title: '첫 번째 퀘스트를 시작해 보세요',
                  message: '매일 하고 싶은 작은 일을 등록하고\n오늘의 도전을 채워 보세요.',
                  action: onManage == null
                      ? null
                      : FilledButton.icon(
                          onPressed: onManage,
                          icon: const Icon(Icons.add),
                          label: const Text('퀘스트 관리하기'),
                        ),
                ),
            ],
          ),
        ),
        for (final category in categoryOrder)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverList.builder(
              itemCount: groupedJobs[category]!.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CategoryBar(
                    name: category,
                    count: groupedJobs[category]!.length,
                  );
                }
                final job = groupedJobs[category]![index - 1];
                return DailyQuestTile(
                  key: ValueKey(job.jobId),
                  job: job,
                  onChanged: (value) => onToggleCompleted(job.jobId, value),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(CategoryBadge.iconFor(name), size: 16, color: QuestTheme.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: QuestTheme.purple,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count개',
            style: const TextStyle(color: QuestTheme.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
