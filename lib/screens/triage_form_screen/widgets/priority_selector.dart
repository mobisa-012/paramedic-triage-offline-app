import 'package:flutter/material.dart';

const priorityColors = <int, Color>{
  1: Color(0xFFB71C1C), // P1 — absolute critical, deep red
  2: Color(0xFFE65100), // P2 — critical, deep orange
  3: Color(0xFFF9A825), // P3 — urgent, amber
  4: Color(0xFF546E7A), // P4 — standard, blue-grey
  5: Color(0xFF78909C), // P5 — minor, light blue-grey
};

const priorityLabels = <int, String>{
  1: 'CRITICAL',
  2: 'SEVERE',
  3: 'URGENT',
  4: 'STANDARD',
  5: 'MINOR',
};

class PrioritySelector extends StatelessWidget {
  const PrioritySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.error,
  });

  final int? selected;
  final ValueChanged<int> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var level = 1; level <= 5; level++) ...[
              Expanded(
                child: _PriorityButton(
                  level: level,
                  isSelected: selected == level,
                  onTap: () => onChanged(level),
                ),
              ),
              if (level < 5) const SizedBox(width: 8),
            ],
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  final int level;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = priorityColors[level]!;
    final critical = level <= 2;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Priority $level, ${priorityLabels[level]}',
      child: Material(
        color: isSelected ? color : color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color,
                width: isSelected ? 0 : (critical ? 2 : 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$level',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                Text(
                  critical && !isSelected ? '⚠ ${priorityLabels[level]}' : priorityLabels[level]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
