import 'package:flutter/material.dart';

import '../models/quest_job.dart';
import '../models/category.dart';
import '../widgets/job_tile.dart';

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

  void showJobDialog(
    BuildContext context, {
    QuestJob? job,
  }) {
    String name = job?.name ?? '';
    int categoryId = job?.categoryId ?? categories.first.id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                job == null ? '퀘스트 추가' : '퀘스트 수정',
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '퀘스트 이름',
                    ),
                    onChanged: (value) {
                      name = value;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
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
                      onUpdateJob(
                        job.id,
                        value,
                        categoryId,
                      );
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

  void showCategoryDialog(
    BuildContext context, {
    QuestCategory? category,
  }) {
    String name = category?.name ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            category == null
                ? '카테고리 추가'
                : '카테고리 수정',
          ),

          content: TextFormField(
            initialValue: name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '카테고리 이름',
            ),
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

  Future<void> confirmDeleteJob(
    BuildContext context,
    QuestJob job,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('퀘스트 삭제'),
          content: Text(
            '${job.name}을(를) 삭제하시겠습니까?',
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
    return Scaffold(
      body: ListView(
        children: [
          // Job 섹션
          ListTile(
            title: const Text(
              '퀘스트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => showJobDialog(context),
            ),
          ),

          if (jobs.isEmpty)
            const ListTile(
              title: Text('등록된 퀘스트가 없습니다.'),
            ),

          ...jobs.map((job) {
            return JobTile(
              key: ValueKey(job.id),
              job: job,
              categoryName: getCategoryName(job.categoryId),
              onToggle: (value) {
                onToggleJob(job.id, value);
              },
              onEdit: () {
                showJobDialog(context, job: job);
              },
              onDelete: () {
                confirmDeleteJob(context, job);
              },
            );
          }),

          const Divider(),

          // Category 섹션
          ListTile(
            title: const Text(
              '카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => showCategoryDialog(context),
            ),
          ),

          ...categories.map((category) {
            return ListTile(
              title: Text(category.name),

              trailing: category.isDefault
                  ? const Text('기본')
                  : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showCategoryDialog(
                            context,
                            category: category,
                          );
                        } else if (value == 'delete') {
                          confirmDeleteCategory(
                            context,
                            category,
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('수정'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제'),
                        ),
                      ],
                    ),
            );
          }),
        ],
      ),
    );
  }
}