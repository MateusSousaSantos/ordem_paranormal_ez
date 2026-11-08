import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';

/// Shows a character sheet and reports every edit through [onChanged].
/// Used both by the player (own sheet) and by the GM (any sheet).
class SheetView extends StatelessWidget {
  const SheetView({super.key, required this.sheet, required this.onChanged});

  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(sheet.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final key in sheet.resources.keys)
          _ResourceRow(
            label: GameRules.resourceLabels[key] ?? key,
            resource: sheet.resources[key]!,
            onDelta: (d) => onChanged(sheet.adjustResource(key, d)),
            onMaxChanged: (m) =>
                onChanged(sheet.withResource(key, sheet.resources[key]!.copyWith(max: m))),
          ),
        const SizedBox(height: 16),
        Text('Attributes', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in sheet.attributes.keys)
              _AttributeChip(
                label: key,
                value: sheet.attributes[key]!,
                onChanged: (v) => onChanged(sheet.withAttribute(key, v)),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.label,
    required this.resource,
    required this.onDelta,
    required this.onMaxChanged,
  });

  final String label;
  final Resource resource;
  final ValueChanged<int> onDelta;
  final ValueChanged<int> onMaxChanged;

  @override
  Widget build(BuildContext context) {
    final ratio = resource.max == 0 ? 0.0 : resource.current / resource.max;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
                IconButton(icon: const Icon(Icons.remove), onPressed: () => onDelta(-1)),
                GestureDetector(
                  onTap: () => _editMax(context),
                  child: Text('${resource.current} / ${resource.max}',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: () => onDelta(1)),
              ],
            ),
            LinearProgressIndicator(value: ratio.clamp(0.0, 1.0), minHeight: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _editMax(BuildContext context) async {
    final controller = TextEditingController(text: '${resource.max}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Max $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && value >= 0) onMaxChanged(value);
  }
}

class _AttributeChip extends StatelessWidget {
  const _AttributeChip({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove, size: 18),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Column(
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text('$value', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ),
    );
  }
}
