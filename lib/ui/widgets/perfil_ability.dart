import 'package:flutter/material.dart';

import '../../game/character_sheet.dart';
import '../theme/sheet_style.dart';

/// The ability tied to the character's perfil psicológico, or nothing when
/// that perfil's ability isn't implemented yet.
class PerfilAbility extends StatelessWidget {
  const PerfilAbility({super.key, required this.sheet, required this.onChanged});

  final CharacterSheet sheet;
  final ValueChanged<CharacterSheet> onChanged;

  /// Whether [perfil] has an ability panel to show.
  static bool hasAbility(PerfilPsicologico perfil) => perfil == PerfilPsicologico.executor;

  @override
  Widget build(BuildContext context) {
    return switch (sheet.perfil) {
      PerfilPsicologico.executor => SlotBar(
          label: 'Ímpeto',
          slots: GameRules.impetoMax,
          filled: sheet.impeto,
          onChanged: (v) => onChanged(sheet.copyWith(impeto: v)),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// A labelled row of [slots] wide boxes, [filled] of them lit.
/// Tap a slot to fill up to it; tap the last filled slot to empty it.
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
    return Container(
      color: SheetStyle.panel,
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SheetStyle.mono(13, bold: true)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < slots; i++)
                Semantics(
                  label: '$label ${i + 1}',
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(filled == i + 1 ? i : i + 1),
                    child: Padding(
                      padding: EdgeInsets.only(right: i == slots - 1 ? 0 : 4),
                      child: Container(
                        width: 30,
                        height: 16,
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
        ],
      ),
    );
  }
}
