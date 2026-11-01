import 'package:flutter/material.dart';

class MonthPickerDialog extends StatefulWidget {
  const MonthPickerDialog({
    super.key,
    required this.initialMonth,
    required this.firstDay,
    required this.lastDay,
  });

  final DateTime initialMonth;
  final DateTime firstDay;
  final DateTime lastDay;

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _year = widget.initialMonth.year;
  late int _month = widget.initialMonth.month;

  int get _firstMonth =>
      _year == widget.firstDay.year ? widget.firstDay.month : 1;
  int get _lastMonth =>
      _year == widget.lastDay.year ? widget.lastDay.month : 12;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('연월 선택'),
      scrollable: true,
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              key: const ValueKey('month-picker-year'),
              initialValue: _year,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '연도'),
              items: [
                for (
                  var year = widget.firstDay.year;
                  year <= widget.lastDay.year;
                  year++
                )
                  DropdownMenuItem(value: year, child: Text('$year년')),
              ],
              onChanged: (year) {
                if (year == null) return;
                setState(() {
                  _year = year;
                  _month = _month.clamp(_firstMonth, _lastMonth);
                });
              },
            ),
            const SizedBox(height: 16),
            for (var row = 0; row < 4; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (var column = 0; column < 3; column++) ...[
                      if (column > 0) const SizedBox(width: 8),
                      Expanded(child: _buildMonth(row * 3 + column + 1)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, DateTime(_year, _month, 1)),
          child: const Text('이동'),
        ),
      ],
    );
  }

  Widget _buildMonth(int month) {
    final selected = _month == month;
    final enabled = month >= _firstMonth && month <= _lastMonth;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        key: ValueKey('month-picker-month-$month'),
        onPressed: enabled ? () => setState(() => _month = month) : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          foregroundColor: selected
              ? colors.onPrimaryContainer
              : colors.onSurface,
          backgroundColor: selected ? colors.primaryContainer : null,
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('$month월'),
      ),
    );
  }
}
