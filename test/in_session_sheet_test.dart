import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opez/game/character_sheet.dart';
import 'package:opez/ui/widgets/in_session_sheet.dart';

void main() {
  testWidgets('tapping a PV box sets current PV to that box', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var sheet = GameRules.newSheet(id: 'x', name: 'Arthur Cervero');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InSessionSheet(sheet: sheet, onChanged: (s) => sheet = s, onClose: () {}),
      ),
    ));

    expect(find.text('Perícias'), findsOneWidget);

    // PV boxes are the first 10 tappable squares after the PV label.
    final boxes = find.descendant(
      of: find.byType(Wrap).first,
      matching: find.byType(GestureDetector),
    );
    expect(boxes, findsNWidgets(10));
    await tester.tap(boxes.at(4));
    expect(sheet.pv.current, 5);
  });
}
