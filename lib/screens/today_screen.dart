import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_job.dart';
import '../theme/quest_theme.dart';
import '../widgets/quest_widgets.dart';

class TodayScreen extends StatelessWidget {
  final List<DailyJob> jobs;
  final void Function(int, bool) onToggleCompleted;
  final VoidCallback? onManage;

  const TodayScreen({
    super.key,
    required this.jobs,
    required this.onToggleCompleted,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final completed = jobs.where((job) => job.isCompleted).length;
    final progress = jobs.isEmpty ? 0.0 : completed / jobs.length;
    final allDone = jobs.isNotEmpty && completed == jobs.length;
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
              const SizedBox(height: 10),
              Text(
                allDone ? '오늘의 퀘스트, 클리어!' : '작은 도전,\n한 걸음 더 성장하는 오늘.',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(height: 1.35),
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
                subtitle: '하나씩 완료하며 나만의 페이스를 만들어 보세요.',
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) => DailyQuestTile(
              key: ValueKey(jobs[index].jobId),
              job: jobs[index],
              onChanged: (value) => onToggleCompleted(jobs[index].jobId, value),
            ),
          ),
        ),
      ],
    );
  }
}
