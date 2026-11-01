import 'package:flutter/material.dart';

import '../theme/quest_theme.dart';

/// A date whose numerals fill from bottom to top with that day's progress.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.progress,
    this.selected = false,
    this.today = false,
  });

  final DateTime day;
  final double? progress;
  final bool selected;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final value = progress?.clamp(0.0, 1.0);
    final complete = value == 1.0;
    final description =
        '${day.month}월 ${day.day}일'
        '${today ? ', 오늘' : ''}'
        '${value == null ? ', 기록 없음' : ', 달성률 ${(value * 100).round()}%'}'
        '${complete ? ', 모두 완료' : ''}';

    return Tooltip(
      message: description,
      excludeFromSemantics: true,
      child: Semantics(
        label: description,
        selected: selected,
        excludeSemantics: true,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF302347) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected || today
                ? Border.all(
                    color: QuestTheme.purple,
                    width: selected ? 1.5 : 1,
                  )
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _FilledDayNumber(day: day.day, progress: value),
                  ),
                ),
              ),
              SizedBox(
                height: 16,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (complete)
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: QuestTheme.lime,
                        ),
                      if (today) ...[
                        if (complete) const SizedBox(width: 2),
                        const Text(
                          '오늘',
                          style: TextStyle(
                            fontSize: 9,
                            color: QuestTheme.purple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else if (value == null)
                        const Text(
                          '–',
                          style: TextStyle(
                            fontSize: 11,
                            color: QuestTheme.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilledDayNumber extends StatelessWidget {
  const _FilledDayNumber({required this.day, required this.progress});

  final int day;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 30,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
    );
    if (progress == null) {
      return Text('$day', style: style.copyWith(color: QuestTheme.muted));
    }
    final fill = progress == 1 ? QuestTheme.lime : QuestTheme.purple;
    final boundary = 1 - progress!;
    return Stack(
      alignment: Alignment.center,
      children: [
        // The outline keeps an empty (0%) date readable without implying progress.
        Text(
          '$day',
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = QuestTheme.muted,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF393347),
              const Color(0xFF393347),
              fill,
              fill,
            ],
            stops: [0, boundary, boundary, 1],
          ).createShader(bounds),
          child: Text('$day', style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
