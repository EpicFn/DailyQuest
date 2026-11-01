import 'package:flutter/material.dart';

import '../models/daily_job.dart';
import '../theme/quest_theme.dart';

class QuestSurface extends StatelessWidget {
  const QuestSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Material(
    color: QuestTheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: QuestTheme.border),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class QuestSectionHeading extends StatelessWidget {
  const QuestSectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String title;
  final String subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(color: QuestTheme.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    ),
  );
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.name, {super.key});
  final String name;
  static IconData iconFor(String name) => switch (name) {
    '건강' => Icons.favorite_outline_rounded,
    '학습' => Icons.auto_stories_outlined,
    '생활' => Icons.home_outlined,
    _ => Icons.auto_awesome_outlined,
  };
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(iconFor(name), size: 14, color: QuestTheme.purple),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          name,
          style: const TextStyle(color: QuestTheme.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

class QuestEmptyState extends StatelessWidget {
  const QuestEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.flag_outlined,
    this.action,
  });
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => QuestSurface(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 36, color: QuestTheme.purple),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: QuestTheme.muted, height: 1.6),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

class DailyQuestTile extends StatelessWidget {
  const DailyQuestTile({super.key, required this.job, this.onChanged});
  final DailyJob job;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) {
    final title = Text(
      job.jobName,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: job.isCompleted ? QuestTheme.muted : null,
        decoration: job.isCompleted ? TextDecoration.lineThrough : null,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: QuestSurface(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: onChanged != null
            ? CheckboxListTile(
                title: title,
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: CategoryBadge(job.categoryName),
                ),
                value: job.isCompleted,
                activeColor: QuestTheme.lime,
                checkColor: const Color(0xFF24330F),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onChanged: (value) {
                  if (value != null) onChanged!(value);
                },
              )
            : ListTile(
                leading: Icon(
                  job.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: job.isCompleted ? QuestTheme.lime : QuestTheme.muted,
                  semanticLabel: job.isCompleted ? '완료' : '미완료',
                ),
                title: title,
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: CategoryBadge(job.categoryName),
                ),
              ),
      ),
    );
  }
}
