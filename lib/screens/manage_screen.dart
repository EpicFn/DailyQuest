import 'package:flutter/material.dart';

import '../models/quest_job.dart';
import '../models/category.dart';
import '../widgets/job_tile.dart';
import '../widgets/quest_widgets.dart';
import '../theme/quest_theme.dart';

class ManageScreen extends StatefulWidget {
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

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  int? _selectedCategoryId;
  bool _activeOnly = false;

  @override
  void didUpdateWidget(covariant ManageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCategoryId != null &&
        !widget.categories.any(
          (category) => category.id == _selectedCategoryId,
        )) {
      _selectedCategoryId = null;
    }
  }
  // --------------------
  // Job 추가 / 수정
  // --------------------

  void showJobDialog(BuildContext context, {QuestJob? job}) {
    String name = job?.name ?? '';
    int categoryId =
        job?.categoryId ?? _selectedCategoryId ?? widget.categories.first.id;

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
                    items: widget.categories.map((category) {
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
                      widget.onAddJob(value, categoryId);
                    } else {
                      widget.onUpdateJob(job.id, value, categoryId);
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
                  widget.onAddCategory(value);
                } else {
                  widget.onUpdateCategory(category.id, value);
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
      widget.onDeleteJob(job.id);
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
          content: Text(
            '“${category.name}” 카테고리를 삭제하시겠습니까?\n'
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
      widget.onDeleteCategory(category.id);
    }
  }

  // --------------------
  // Category 이름 조회
  // --------------------

  String getCategoryName(int categoryId) {
    for (final category in widget.categories) {
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
    final active = widget.jobs.where((job) => job.isActive).length;
    final groupedJobs = <int, List<QuestJob>>{};
    for (final job in widget.jobs) {
      groupedJobs.putIfAbsent(job.categoryId, () => []).add(job);
    }
    final categoryOrder = <int>{
      ...widget.categories.map((category) => category.id),
      ...groupedJobs.keys,
    };
    final categoryJobs = _selectedCategoryId == null
        ? [for (final id in categoryOrder) ...?groupedJobs[id]]
        : groupedJobs[_selectedCategoryId] ?? <QuestJob>[];
    final visibleJobs = _activeOnly
        ? categoryJobs.where((job) => job.isActive).toList()
        : categoryJobs;
    final selectedCategory = widget.categories
        .where((category) => category.id == _selectedCategoryId)
        .firstOrNull;
    return ListView(
      key: const PageStorageKey('manage'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        QuestSectionHeading(
          title: '퀘스트 선택',
          subtitle: '스위치로 퀘스트를 활성화하세요.',
          action: FilledButton.icon(
            onPressed: widget.categories.isEmpty
                ? null
                : () => showJobDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('추가'),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('category-filter-active'),
              label: Text('진행 중 $active'),
              selected: _activeOnly,
              onSelected: (_) => setState(() {
                _selectedCategoryId = null;
                _activeOnly = true;
              }),
            ),
            ChoiceChip(
              key: const ValueKey('category-filter-all'),
              label: Text('전체 ${widget.jobs.length}'),
              selected: _selectedCategoryId == null && !_activeOnly,
              onSelected: (_) => setState(() {
                _selectedCategoryId = null;
                _activeOnly = false;
              }),
            ),
            for (final category in widget.categories)
              ChoiceChip(
                key: ValueKey('category-filter-${category.id}'),
                label: Text(
                  '${category.name} ${groupedJobs[category.id]?.length ?? 0}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: _selectedCategoryId == category.id,
                onSelected: (_) => setState(() {
                  _selectedCategoryId = category.id;
                  _activeOnly = false;
                }),
              ),
            IconButton.outlined(
              tooltip: '카테고리 추가',
              onPressed: () => showCategoryDialog(context),
              icon: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
        if (selectedCategory != null && !selectedCategory.isDefault)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  key: const ValueKey('edit-selected-category'),
                  onPressed: () =>
                      showCategoryDialog(context, category: selectedCategory),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('이름 수정'),
                ),
                TextButton.icon(
                  key: const ValueKey('delete-selected-category'),
                  onPressed: () =>
                      confirmDeleteCategory(context, selectedCategory),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('카테고리 삭제'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (visibleJobs.isEmpty)
          QuestEmptyState(
            title: _activeOnly
                ? '진행 중인 퀘스트가 없어요'
                : _selectedCategoryId == null
                ? '등록된 퀘스트가 없어요'
                : '이 카테고리에 퀘스트가 없어요',
            message: _activeOnly
                ? '전체에서 퀘스트를 활성화하거나\n새 퀘스트를 추가해 보세요.'
                : '위의 추가 버튼으로 시작해 보세요.',
          ),
        ...visibleJobs.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: JobTile(
              key: ValueKey(job.id),
              job: job,
              categoryName: getCategoryName(job.categoryId),
              onToggle: (value) => widget.onToggleJob(job.id, value),
              onEdit: () => showJobDialog(context, job: job),
              onDelete: () => confirmDeleteJob(context, job),
            ),
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
