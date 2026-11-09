import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';
import 'die_stepper.dart';

/// A character sheet during play. Reports every edit through [onChanged].
/// Used by the player (own character) and by the GM (any character).
class SheetView extends StatelessWidget {
  const SheetView({super.key, required this.sheet, required this.onChanged});

  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      'Nível ${sheet.nivel}',
      if (sheet.vocacao.isNotEmpty) sheet.vocacao,
      sheet.perfil.label,
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(sheet.name.isEmpty ? 'Sem nome' : sheet.name, style: theme.textTheme.headlineSmall),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        ResourceRow(
          label: 'PV',
          resource: sheet.pv,
          onDelta: (d) => onChanged(sheet.adjustPv(d)),
          onMaxChanged: (m) => onChanged(sheet.copyWith(pv: sheet.pv.copyWith(max: m))),
        ),
        ResourceRow(
          label: 'PD',
          resource: sheet.pd,
          onDelta: (d) => onChanged(sheet.adjustPd(d)),
          onMaxChanged: (m) => onChanged(sheet.copyWith(pd: sheet.pd.copyWith(max: m))),
        ),
        const SizedBox(height: 16),
        Text('Atributos', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in GameRules.atributos)
              DieStepper(
                label: GameRules.atributoLabels[key]!,
                die: sheet.atributos[key]!,
                onChanged: (d) => onChanged(sheet.withAtributo(key, d)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Perícias', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in GameRules.pericias)
              DieStepper(
                label: key,
                die: sheet.pericias[key]!,
                onChanged: (d) => onChanged(sheet.withPericia(key, d)),
              ),
          ],
        ),
      ],
    );
  }
}

/// PV / PD bar with -/+ buttons. Tap the numbers to change the maximum.
class ResourceRow extends StatelessWidget {
  const ResourceRow({
    super.key,
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
        title: Text('$label máximo'),
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
