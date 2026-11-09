import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opez/core/json_store.dart';
import 'package:opez/game/character_library.dart';
import 'package:opez/game/character_sheet.dart';
import 'package:opez/host/host_session.dart';
import 'package:opez/player/player_session.dart';

/// Waits until [condition] is true, polling the event loop.
Future<void> until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

JsonStore tempStore() {
  final dir = Directory.systemTemp.createTempSync('opez_test');
  return JsonStore(() async => dir);
}

Future<CharacterSheet> savedCharacter(CharacterLibrary library, String name) async {
  final c = library.create().copyWith(name: name);
  await library.save(c);
  return c;
}

void main() {
  test('player joins, edits sync to GM, GM edits sync back', () async {
    final host = HostSession(store: tempStore());
    await host.start(name: 'Mesa', port: 0);

    final library = CharacterLibrary(store: tempStore());
    await library.load();
    final arthur = await savedCharacter(library, 'Arthur');

    final player = PlayerSession(store: tempStore(), library: library);
    await player.load();
    await player.connect(host: '127.0.0.1', port: host.port!, character: arthur);
    await until(() => player.status == ConnectionStatus.connected);

    expect(player.sessionName, 'Mesa');
    expect(host.sheets.single.name, 'Arthur');
    expect(host.isOnline(arthur.id), isTrue);

    // Player takes damage.
    player.updateSheet(player.sheet!.adjustPv(-4));
    await until(() => host.sheets.single.pv.current == 6);

    // GM heals them and raises a perícia; the saved character follows.
    host.updateSheet(host.sheets.single.adjustPv(2).withPericia(GameRules.pericias.first, Die.d8));
    await until(() => player.sheet!.pv.current == 8);
    expect(library.byId(arthur.id)!.pericias[GameRules.pericias.first], Die.d8);

    await player.disconnect();
    await until(() => !host.isOnline(arthur.id));
    await host.stop();
  });

  test('saved character keeps its progress across sessions', () async {
    final host = HostSession(store: tempStore());
    await host.start(port: 0);

    final libraryStore = tempStore();
    final library = CharacterLibrary(store: libraryStore);
    await library.load();
    final dante = await savedCharacter(library, 'Dante');

    final p1 = PlayerSession(store: tempStore(), library: library);
    await p1.connect(host: '127.0.0.1', port: host.port!, character: dante);
    await until(() => p1.status == ConnectionStatus.connected);
    p1.updateSheet(p1.sheet!.withAtributo('fisico', Die.d10));
    await until(() => host.sheets.single.atributos['fisico'] == Die.d10);
    await p1.disconnect();

    // App restarted: library reloaded from disk.
    final reloaded = CharacterLibrary(store: libraryStore);
    await reloaded.load();
    final again = reloaded.byId(dante.id)!;
    expect(again.atributos['fisico'], Die.d10);

    final p2 = PlayerSession(store: tempStore(), library: reloaded);
    await p2.connect(host: '127.0.0.1', port: host.port!, character: again);
    await until(() => p2.status == ConnectionStatus.connected);
    expect(host.sheets, hasLength(1));

    await p2.disconnect();
    await host.stop();
  });
}
