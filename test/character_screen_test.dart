import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opez/core/json_store.dart';
import 'package:opez/game/character_library.dart';
import 'package:opez/game/character_sheet.dart';
import 'package:opez/ui/character_edit_screen.dart';

void main() {
  testWidgets('creating a character saves it to the library', (tester) async {
    final dir = Directory.systemTemp.createTempSync('opez_ui');
    final library = CharacterLibrary(store: JsonStore(() async => dir));
    final draft = library.create();

    await tester.pumpWidget(MaterialApp(
      home: CharacterEditScreen(library: library, initial: draft),
    ));

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome'), 'Arthur Cervero');
    await tester.enterText(find.widgetWithText(TextFormField, 'Vocação'), 'Ocultista');
    await tester.enterText(find.widgetWithText(TextFormField, 'PV máximo'), '18');
    await tester.tap(find.text('Analista'));
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(find.text('Salvar'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    final saved = library.byId(draft.id)!;
    expect(saved.name, 'Arthur Cervero');
    expect(saved.vocacao, 'Ocultista');
    expect(saved.perfil, PerfilPsicologico.analista);
    expect(saved.pv.max, 18);
    expect(saved.pv.current, 18);
  });
}
