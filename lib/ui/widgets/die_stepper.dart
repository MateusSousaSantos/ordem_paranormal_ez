import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';

/// Shows a die (d4..d20) with buttons to step it down or up.
/// Read-only when [onChanged] is null.
class DieStepper extends StatelessWidget {
  const DieStepper({super.key, required this.label, required this.die, this.onChanged});

  final String label;
  final Die die;
  final ValueChanged<Die>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = onChanged;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (change != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 18),
                onPressed: die.previous == null ? null : () => change(die.previous!),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: change == null ? 12 : 0),
              child: Column(
                children: [
                  Text(label, style: theme.textTheme.labelSmall),
                  Text(die.label, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            if (change != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 18),
                onPressed: die.next == null ? null : () => change(die.next!),
              ),
          ],
        ),
      ),
    );
  }
}
