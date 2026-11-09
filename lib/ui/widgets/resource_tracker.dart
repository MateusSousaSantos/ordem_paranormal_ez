import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';
import '../theme/sheet_style.dart';

/// PV / PD tracker: a label, a circle with the current value, and one box per
/// point. Filled boxes are points left, outlined boxes are points spent.
/// Tap a box to set the value there; tap the circle to type values.
class ResourceTracker extends StatelessWidget {
  const ResourceTracker({
    super.key,
    required this.label,
    required this.resource,
    required this.onChanged,
  });

  final String label;
  final Resource resource;
  final ValueChanged<Resource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _edit(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(6, 2, 10, 2),
                decoration: BoxDecoration(
                  color: SheetStyle.box,
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    Text(label, style: SheetStyle.fredoka(18, weight: 650, color: SheetStyle.dark)),
              ),
              Transform.translate(
                offset: const Offset(-6, 0),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SheetStyle.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: SheetStyle.box, width: 3),
                  ),
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child:
                          Text('${resource.current}', style: SheetStyle.fredoka(20, weight: 650)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: _BoxGrid(resource: resource, onChanged: onChanged)),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final current = TextEditingController(text: '${resource.current}');
    final max = TextEditingController(text: '${resource.max}');
    final result = await showDialog<Resource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: current,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Atual'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: max,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Máximo'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final m = int.tryParse(max.text);
              final c = int.tryParse(current.text);
              if (m == null || c == null || m < 0) return;
              Navigator.pop(context, Resource(current: c, max: m).copyWith());
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _BoxGrid extends StatelessWidget {
  const _BoxGrid({required this.resource, required this.onChanged});

  final Resource resource;
  final ValueChanged<Resource> onChanged;

  static const gap = 4.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final count = resource.max;
      if (count == 0) return const SizedBox();
      final w = constraints.maxWidth;
      final h = constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity;
      // Biggest box that fits; at most 8 per row like the paper sheet,
      // more only when the rows would not fit.
      var size = 6.0;
      var cols = 8;
      for (var s = 18.0; s >= 6; s -= 1) {
        final fit = ((w + gap) / (s + gap)).floor();
        if (fit < 1) continue;
        final c = fit < 8 ? fit : 8;
        final rows = (count / c).ceil();
        if (rows * (s + gap) - gap <= h) {
          size = s;
          cols = c;
          break;
        }
        final rowsWide = (count / fit).ceil();
        if (rowsWide * (s + gap) - gap <= h) {
          size = s;
          cols = fit;
          break;
        }
      }
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: cols * (size + gap),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < count; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final target = resource.current == i + 1 ? i : i + 1;
                    onChanged(resource.copyWith(current: target));
                  },
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: i < resource.current ? SheetStyle.box : Colors.transparent,
                      border: Border.all(color: SheetStyle.box, width: 1.5),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}
