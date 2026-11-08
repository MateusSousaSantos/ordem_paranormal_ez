import 'package:flutter_test/flutter_test.dart';
import 'package:opez/core/protocol.dart';
import 'package:opez/game/character_sheet.dart';

void main() {
  test('messages survive an encode/decode round trip', () {
    final sheet = GameRules.newSheet(id: 'p1', name: 'Arthur').adjustResource('PV', -3);
    final hello = Message.decode(
        HelloMessage(playerId: 'p1', playerName: 'Arthur', sheet: sheet).encode());
    expect(hello, isA<HelloMessage>());
    hello as HelloMessage;
    expect(hello.sheet!.resources['PV']!.current, 7);
    expect(hello.role, ClientRole.player);

    final changed = Message.decode(SheetChangedMessage(sheet).encode()) as SheetChangedMessage;
    expect(changed.sheet.toJson(), sheet.toJson());
  });

  test('resources clamp between 0 and max', () {
    final sheet = GameRules.newSheet(id: 'p1', name: 'A');
    expect(sheet.adjustResource('PV', -50).resources['PV']!.current, 0);
    expect(sheet.adjustResource('PV', 50).resources['PV']!.current, 10);
  });
}
