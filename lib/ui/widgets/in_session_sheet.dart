import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';
import '../theme/sheet_style.dart';
import 'die_badge.dart';
import 'perfil_ability.dart';
import 'resource_tracker.dart';

/// The landscape character sheet used during a session.
class InSessionSheet extends StatelessWidget {
  const InSessionSheet({
    super.key,
    required this.sheet,
    required this.onChanged,
    required this.onClose,
    this.statusIcon,
  });

  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onChanged;
  final VoidCallback onClose;
  final Widget? statusIcon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SheetStyle.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(sheet: sheet, onClose: onClose, statusIcon: statusIcon),
            const SizedBox(height: 4),
            Container(height: 3, color: SheetStyle.ink),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Atributos(sheet: sheet, onChanged: onChanged),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ResourceTracker(
                                        label: 'PV',
                                        tilt: -0.08,
                                        resource: sheet.pv,
                                        onChanged: (r) => onChanged(sheet.copyWith(pv: r)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ResourceTracker(
                                        label: 'PD',
                                        tilt: -0.05,
                                        resource: sheet.pd,
                                        onChanged: (r) => onChanged(sheet.copyWith(pd: r)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 78,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // The perfil's own ability (Ímpeto for Executor...).
                              Expanded(
                                child: PerfilAbility(sheet: sheet, onChanged: onChanged),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 104,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _PanelButton(
                                        label: 'Perícias',
                                        onTap: () => showPericias(context, sheet, onChanged),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: _PanelButton(
                                        label: 'Inventário',
                                        onTap: () => showInventario(context, sheet, onChanged),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right-side panel from the mockup; content still to be defined.
                  Expanded(
                    flex: 3,
                    child: Container(color: SheetStyle.sidePanel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sheet, required this.onClose, this.statusIcon});

  final CharacterSheet sheet;
  final VoidCallback onClose;
  final Widget? statusIcon;

  @override
  Widget build(BuildContext context) {
    final name = sheet.name.trim();
    final split = name.indexOf(' ');
    final first = split < 0 ? name : name.substring(0, split);
    final rest = split < 0 ? '' : name.substring(split + 1);
    const dot = Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Icon(Icons.circle_outlined, size: 9, color: SheetStyle.ink),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: first.isEmpty ? 'Sem nome' : first,
                  style: SheetStyle.fredoka(30, weight: 350)),
              if (rest.isNotEmpty)
                TextSpan(text: '  $rest', style: SheetStyle.fredoka(17, weight: 350)),
            ])),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomRight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(sheet.perfil.label.toUpperCase(), style: SheetStyle.fredoka(17, weight: 700)),
                if (sheet.vocacao.isNotEmpty) ...[
                  dot,
                  Text(sheet.vocacao, style: SheetStyle.fredoka(17, weight: 350)),
                ],
                dot,
                Text('nível ${sheet.nivel}', style: SheetStyle.fredoka(17, weight: 350)),
                if (statusIcon != null) ...[const SizedBox(width: 12), statusIcon!],
                const SizedBox(width: 10),
                Material(
                  color: SheetStyle.ink,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 20, color: SheetStyle.background),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Atributos extends StatelessWidget {
  const _Atributos({required this.sheet, required this.onChanged});

  /// Rotation in radians for each attribute row.
  static const _tilt = {'fisico': -0.07, 'mente': 0.05, 'emocao': -0.05};

  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onChanged;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in GameRules.atributos)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // Hand-drawn tilt from the paper design.
              child: Transform.rotate(
                angle: _tilt[key]!,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(GameRules.atributoLabels[key]!,
                        style: SheetStyle.fredoka(26, weight: 600)),
                    const SizedBox(width: 8),
                    DieBadge(
                      die: sheet.atributos[key]!,
                      size: 36,
                      onTap: () async {
                        final d = await pickDie(context,
                            title: GameRules.atributoLabels[key]!, current: sheet.atributos[key]!);
                        if (d != null) onChanged(sheet.withAtributo(key, d));
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SheetStyle.panel,
      child: InkWell(
        onTap: onTap,
        child: Center(child: Text(label, style: SheetStyle.mono(13, bold: true))),
      ),
    );
  }
}

/// Dialog with the 20 perícias. Changes are applied immediately.
Future<void> showPericias(
    BuildContext context, CharacterSheet sheet, ValueChanged<CharacterSheet> onChanged) {
  var current = sheet;
  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: SheetStyle.background,
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Perícias', style: SheetStyle.fredoka(22, weight: 600)),
              const SizedBox(height: 8),
              Flexible(
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  childAspectRatio: 3.6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final key in GameRules.pericias)
                      Material(
                        color: SheetStyle.panel,
                        child: InkWell(
                          onTap: () async {
                            final d =
                                await pickDie(context, title: key, current: current.pericias[key]!);
                            if (d == null) return;
                            current = current.withPericia(key, d);
                            onChanged(current);
                            setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(key,
                                      style: SheetStyle.mono(11, bold: true),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                DieBadge(die: current.pericias[key]!, size: 26),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Dialog to add and remove inventory items.
Future<void> showInventario(
    BuildContext context, CharacterSheet sheet, ValueChanged<CharacterSheet> onChanged) {
  var current = sheet;
  final input = TextEditingController();
  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void add() {
          final item = input.text.trim();
          if (item.isEmpty) return;
          current = current.copyWith(inventario: [...current.inventario, item]);
          onChanged(current);
          input.clear();
          setState(() {});
        }

        return Dialog(
          backgroundColor: SheetStyle.background,
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Inventário', style: SheetStyle.fredoka(22, weight: 600)),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (current.inventario.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text('Vazio', style: SheetStyle.mono(12)),
                          ),
                        for (var i = 0; i < current.inventario.length; i++)
                          ListTile(
                            dense: true,
                            title: Text(current.inventario[i], style: SheetStyle.mono(12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: SheetStyle.ink),
                              onPressed: () {
                                current = current.copyWith(
                                    inventario: [...current.inventario]..removeAt(i));
                                onChanged(current);
                                setState(() {});
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          style: SheetStyle.mono(12),
                          decoration: const InputDecoration(hintText: 'Novo item'),
                          onSubmitted: (_) => add(),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.add, color: SheetStyle.ink), onPressed: add),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
