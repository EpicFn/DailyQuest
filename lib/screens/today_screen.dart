import 'package:flutter/material.dart';

import '../models/daily_job.dart';

class TodayScreen extends StatelessWidget {
  final List<DailyJob> jobs;
  final void Function(int, bool) onToggleCompleted;

  const TodayScreen({
    super.key,
    required this.jobs,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = jobs.where((job) => job.isCompleted).length;

    final progress = jobs.isEmpty ? 0.0 : completedCount / jobs.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 달성률 ${(progress * 100).round()}%',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),

          const SizedBox(height: 8),

          Text('완료 $completedCount / ${jobs.length}'),

          const SizedBox(height: 24),

          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text('활성화된 퀘스트가 없습니다.'))
                : ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];

                      return CheckboxListTile(
                        title: Text(
                          job.jobName,
                          style: TextStyle(
                            decoration: job.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        subtitle: Text(job.categoryName),

                        value: job.isCompleted,

                        controlAffinity: ListTileControlAffinity.leading,

                        onChanged: (value) {
                          if (value != null) {
                            onToggleCompleted(job.jobId, value);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
