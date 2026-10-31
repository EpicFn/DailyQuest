import 'package:flutter/material.dart';

import '../models/quest_job.dart';

class JobTile extends StatelessWidget {
  final QuestJob job;
  final String categoryName;

  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JobTile({
    super.key,
    required this.job,
    required this.categoryName,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Switch(
        value: job.isActive,
        onChanged: onToggle,
      ),

      title: Text(job.name),

      subtitle: Text(categoryName),

      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'delete') {
            onDelete();
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
  }
}