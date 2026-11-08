import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opez/core/json_store.dart';
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

void main() {
  test('player joins, edits sync to GM, GM edits sync back', () async {
    final host = HostSession(store: tempStore());
    await host.start(name: 'Mesa', port: 0);

    final player = PlayerSession(store: tempStore());
    await player.load();
    await player.connect(host: '127.0.0.1', port: host.port!, name: 'Arthur');
    await until(() => player.status == ConnectionStatus.connected);

    expect(player.sessionName, 'Mesa');
    expect(host.sheets.single.name, 'Arthur');
    expect(host.isOnline(player.playerId), isTrue);

    // Player takes damage.
    player.updateSheet(player.sheet!.adjustResource('PV', -4));
    await until(() => host.sheets.single.resources['PV']!.current == 6);

    // GM heals them.
    host.updateSheet(host.sheets.single.adjustResource('PV', 2));
    await until(() => player.sheet!.resources['PV']!.current == 8);

    await player.disconnect();
    await until(() => !host.isOnline(player.playerId));
    await host.stop();
  });

  test('player reconnects with the same character', () async {
    final hostStore = tempStore();
    final playerStore = tempStore();
    final host = HostSession(store: hostStore);
    await host.start(port: 0);

    final p1 = PlayerSession(store: playerStore);
    await p1.load();
    await p1.connect(host: '127.0.0.1', port: host.port!, name: 'Dante');
    await until(() => p1.status == ConnectionStatus.connected);
    p1.updateSheet(p1.sheet!.withAttribute('FOR', 3));
    await until(() => host.sheets.single.attributes['FOR'] == 3);
    await p1.disconnect();

    // Same phone opens the app again later.
    final p2 = PlayerSession(store: playerStore);
    await p2.load();
    expect(p2.playerId, p1.playerId);
    await p2.connect(host: '127.0.0.1', port: host.port!, name: 'Dante');
    await until(() => p2.status == ConnectionStatus.connected);
    expect(host.sheets, hasLength(1));
    expect(p2.sheet!.attributes['FOR'], 3);

    await p2.disconnect();
    await host.stop();
  });
}
