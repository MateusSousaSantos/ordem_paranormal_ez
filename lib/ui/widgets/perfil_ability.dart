import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';
import '../theme/sheet_style.dart';

/// The ability tied to the character's perfil psicológico, shown in the
/// bottom panel of the in-session sheet. Perfis whose ability isn't
/// implemented yet show an empty panel with the perfil name.
class PerfilAbility extends StatelessWidget {
  const PerfilAbility({super.key, required this.sheet, required this.onChanged});

  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (sheet.perfil) {
      PerfilPsicologico.executor => SlotBar(
          label: 'Ímpeto',
          slots: GameRules.impetoMax,
          filled: sheet.impeto,
          onChanged: (v) => onChanged(sheet.copyWith(impeto: v)),
        ),
      _ => _AbilityPanel(label: sheet.perfil.label, child: const SizedBox.shrink()),
    };
  }
}

class _AbilityPanel extends StatelessWidget {
  const _AbilityPanel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SheetStyle.panel,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: SheetStyle.mono(15, bold: true)),
          const SizedBox(height: 4),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A labelled row of [slots] boxes, [filled] of them lit, stretched to the
/// panel width. Tap a slot to fill up to it; tap the last filled one to empty it.
class SlotBar extends StatelessWidget {
  const SlotBar({
    super.key,
    required this.label,
    required this.slots,
    required this.filled,
    required this.onChanged,
  });

  final String label;
  final int slots;
  final int filled;
  final ValueChanged<int> onChanged;

  static const _empty = Color(0xFF5A5A5A);

  @override
  Widget build(BuildContext context) {
    return _AbilityPanel(
      label: label,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: 26,
          child: Row(
            children: [
              for (var i = 0; i < slots; i++)
                Expanded(
                  child: Semantics(
                    label: '$label ${i + 1}',
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(filled == i + 1 ? i : i + 1),
                      child: Container(
                        margin: EdgeInsets.only(right: i == slots - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: i < filled ? SheetStyle.box : _empty,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
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
