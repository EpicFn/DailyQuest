import 'package:flutter/material.dart';

import '../models/quest_job.dart';
import '../models/category.dart';
import '../widgets/job_tile.dart';
import '../widgets/quest_widgets.dart';
import '../theme/quest_theme.dart';

class ManageScreen extends StatelessWidget {
  final List<QuestJob> jobs;
  final List<QuestCategory> categories;

  // Job 콜백
  final void Function(String, int) onAddJob;
  final void Function(int, String, int) onUpdateJob;
  final void Function(int) onDeleteJob;
  final void Function(int, bool) onToggleJob;

  // Category 콜백
  final void Function(String) onAddCategory;
  final void Function(int, String) onUpdateCategory;
  final void Function(int) onDeleteCategory;

  const ManageScreen({
    super.key,
    required this.jobs,
    required this.categories,
    required this.onAddJob,
    required this.onUpdateJob,
    required this.onDeleteJob,
    required this.onToggleJob,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
  });

  // --------------------
  // Job 추가 / 수정
  // --------------------

  void showJobDialog(BuildContext context, {QuestJob? job}) {
    String name = job?.name ?? '';
    int categoryId = job?.categoryId ?? categories.first.id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Text(job == null ? '퀘스트 추가' : '퀘스트 수정'),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '퀘스트 이름'),
                    onChanged: (value) {
                      name = value;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: '카테고리'),
                    items: categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        categoryId = value;
                      });
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('취소'),
                ),

                FilledButton(
                  onPressed: () {
                    final value = name.trim();

                    if (value.isEmpty) return;

                    if (job == null) {
                      onAddJob(value, categoryId);
                    } else {
                      onUpdateJob(job.id, value, categoryId);
                    }

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --------------------
  // Category 추가 / 수정
  // --------------------

  void showCategoryDialog(BuildContext context, {QuestCategory? category}) {
    String name = category?.name ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Text(category == null ? '카테고리 추가' : '카테고리 수정'),

          content: TextFormField(
            initialValue: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: '카테고리 이름'),
            onChanged: (value) {
              name = value;
            },
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),

            FilledButton(
              onPressed: () {
                final value = name.trim();

                if (value.isEmpty) return;

                if (category == null) {
                  onAddCategory(value);
                } else {
                  onUpdateCategory(category.id, value);
                }

                Navigator.pop(dialogContext);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // --------------------
  // Job 삭제
  // --------------------

  Future<void> confirmDeleteJob(BuildContext context, QuestJob job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('퀘스트 삭제'),
          content: Text('${job.name}을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onDeleteJob(job.id);
    }
  }

  // --------------------
  // Category 삭제
  // --------------------

  Future<void> confirmDeleteCategory(
    BuildContext context,
    QuestCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('카테고리 삭제'),
          content: const Text(
            '카테고리를 삭제하시겠습니까?\n'
            '해당 카테고리의 퀘스트는 기타로 이동합니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onDeleteCategory(category.id);
    }
  }

  // --------------------
  // Category 이름 조회
  // --------------------

  String getCategoryName(int categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }

    return '기타';
  }

  // --------------------
  // UI
  // --------------------

  @override
  Widget build(BuildContext context) {
    final active = jobs.where((job) => job.isActive).length;
    return ListView(
      key: const PageStorageKey('manage'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('나만의 퀘스트 만들기', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          '매일 반복하고 싶은 일을 모아 보세요.',
          style: TextStyle(color: QuestTheme.muted),
        ),
        const SizedBox(height: 24),
        QuestSurface(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF38265F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: QuestTheme.purple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '진행 중인 퀘스트 $active개',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '활성화한 퀘스트가 오늘 목록에 표시돼요.',
                      style: TextStyle(color: QuestTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        QuestSectionHeading(
          title: '퀘스트 ${jobs.length}',
          subtitle: '스위치로 오늘의 도전을 선택하세요.',
          action: FilledButton.icon(
            onPressed: categories.isEmpty ? null : () => showJobDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('추가'),
          ),
        ),
        if (jobs.isEmpty)
          const QuestEmptyState(
            title: '등록된 퀘스트가 없어요',
            message: '물 한 잔, 책 한 쪽도 좋아요.\n위의 추가 버튼으로 시작해 보세요.',
          ),
        ...jobs.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: JobTile(
              key: ValueKey(job.id),
              job: job,
              categoryName: getCategoryName(job.categoryId),
              onToggle: (value) => onToggleJob(job.id, value),
              onEdit: () => showJobDialog(context, job: job),
              onDelete: () => confirmDeleteJob(context, job),
            ),
          ),
        ),
        QuestSectionHeading(
          title: '카테고리',
          subtitle: '나의 도전을 주제별로 정리해요.',
          action: IconButton.filledTonal(
            tooltip: '카테고리 추가',
            onPressed: () => showCategoryDialog(context),
            icon: const Icon(Icons.add),
          ),
        ),
        QuestSurface(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var index = 0; index < categories.length; index++) ...[
                if (index > 0)
                  const Divider(height: 1, indent: 56, endIndent: 16),
                ListTile(
                  leading: Icon(
                    CategoryBadge.iconFor(categories[index].name),
                    color: QuestTheme.purple,
                    size: 22,
                  ),
                  title: Text(categories[index].name),
                  trailing: categories[index].isDefault
                      ? const Text(
                          '기본',
                          style: TextStyle(
                            color: QuestTheme.muted,
                            fontSize: 12,
                          ),
                        )
                      : PopupMenuButton<String>(
                          tooltip: '${categories[index].name} 관리',
                          onSelected: (value) {
                            if (value == 'edit') {
                              showCategoryDialog(
                                context,
                                category: categories[index],
                              );
                            } else if (value == 'delete') {
                              confirmDeleteCategory(context, categories[index]);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('수정')),
                            PopupMenuItem(value: 'delete', child: Text('삭제')),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.history_rounded, size: 16, color: QuestTheme.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '퀘스트를 바꿔도 지난날의 기록은 그대로 보관돼요.',
                style: TextStyle(
                  color: QuestTheme.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
