import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opez/game/character_sheet.dart';
import 'package:opez/ui/widgets/in_session_sheet.dart';
import 'package:opez/ui/widgets/resource_tracker.dart';

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

    // Inside the PV tracker: the label/circle, then one tappable box per point.
    final boxes = find.descendant(
      of: find.byType(ResourceTracker).first,
      matching: find.byType(GestureDetector),
    );
    expect(boxes, findsNWidgets(11));
    await tester.tap(boxes.at(5));
    expect(sheet.pv.current, 5);
  });
}
