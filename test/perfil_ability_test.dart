import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opez/game/character_sheet.dart';
import 'package:opez/ui/widgets/perfil_ability.dart';

void main() {
  test('Ímpeto is saved and clamped to 0..7', () {
    final sheet = GameRules.newSheet(id: 'x').copyWith(impeto: 3);
    expect(CharacterSheet.fromJson(sheet.toJson()).impeto, 3);
    expect(sheet.copyWith(impeto: 12).impeto, GameRules.impetoMax);
    expect(sheet.copyWith(impeto: -1).impeto, 0);
  });

  testWidgets('Executor gets a 7-slot Ímpeto bar; tapping fills it', (tester) async {
    var sheet = GameRules.newSheet(id: 'x').copyWith(perfil: PerfilPsicologico.executor);
    Future<void> pump() => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: PerfilAbility(sheet: sheet, onChanged: (s) => sheet = s),
          ),
        ));
    await pump();
    expect(find.text('Ímpeto'), findsOneWidget);
    final slots = find.bySemanticsLabel(RegExp(r'^Ímpeto \d$'));
    expect(slots, findsNWidgets(7));

    await tester.tap(slots.at(2));
    expect(sheet.impeto, 3);
    await pump();
    await tester.tap(find.bySemanticsLabel('Ímpeto 3'));
    expect(sheet.impeto, 2);
  });

  testWidgets('other perfis show no Ímpeto bar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PerfilAbility(sheet: GameRules.newSheet(id: 'x'), onChanged: (_) {}),
    ));
    expect(find.text('Ímpeto'), findsNothing);
  });
}
