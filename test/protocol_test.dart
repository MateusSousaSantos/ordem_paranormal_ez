import 'package:flutter_test/flutter_test.dart';
import 'package:opez/core/protocol.dart';
import 'package:opez/game/character_sheet.dart';

void main() {
  test('messages survive an encode/decode round trip', () {
    final sheet = GameRules.newSheet(id: 'p1', name: 'Arthur')
        .copyWith(vocacao: 'Ocultista', nivel: 3, perfil: PerfilPsicologico.analista)
        .withAtributo('mente', Die.d12)
        .withPericia(GameRules.pericias.first, Die.d20)
        .adjustPv(-3);
    final hello =
        Message.decode(HelloMessage(playerId: 'p1', playerName: 'Arthur', sheet: sheet).encode());
    expect(hello, isA<HelloMessage>());
    hello as HelloMessage;
    expect(hello.sheet!.toJson(), sheet.toJson());
    expect(hello.sheet!.pv.current, 7);
    expect(hello.sheet!.atributos['mente'], Die.d12);
    expect(hello.sheet!.perfil, PerfilPsicologico.analista);
  });

  test('PV and PD clamp between 0 and max', () {
    final sheet = GameRules.newSheet(id: 'p1', name: 'A');
    expect(sheet.adjustPv(-50).pv.current, 0);
    expect(sheet.adjustPd(50).pd.current, 10);
  });

  test('dice step between d4 and d20', () {
    expect(Die.d4.previous, isNull);
    expect(Die.d12.next, Die.d20);
    expect(Die.d20.next, isNull);
  });

  test('sheets missing perícias load with d4 defaults', () {
    final json = GameRules.newSheet(id: 'p1', name: 'A').toJson()..['pericias'] = {};
    final sheet = CharacterSheet.fromJson(json);
    expect(sheet.pericias, hasLength(20));
    expect(sheet.pericias.values.toSet(), {Die.d4});
  });

  test('every perícia has a parent atributo', () {
    for (final p in GameRules.pericias) {
      expect(GameRules.atributos, contains(GameRules.periciaAtributo[p]), reason: p);
    }
  });
}
