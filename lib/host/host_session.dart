import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/json_store.dart';
import '../core/protocol.dart';
import '../game/character_sheet.dart';

class _Client {
  _Client(this.socket);

  final WebSocket socket;
  String? playerId;
  ClientRole role = ClientRole.player;

  void send(Message m) => socket.add(m.encode());
}

/// The GM's side of a session. Runs a WebSocket server on this device, keeps
/// every character sheet (the GM device is the source of truth), saves them
/// locally and pushes every change to all connected clients.
class HostSession extends ChangeNotifier {
  HostSession({required this.store, this.onStarted, this.onStopped});

  final JsonStore store;

  /// Hooks used to announce/unannounce the session on the network (mDNS).
  final Future<void> Function(String sessionName, int port)? onStarted;
  final Future<void> Function()? onStopped;

  static const _storeKey = 'campaign';

  HttpServer? _server;
  final List<_Client> _clients = [];
  final Map<String, CharacterSheet> _sheets = {};
  final Set<String> _online = {};

  String sessionName = 'Op.ez session';

  bool get isRunning => _server != null;
  int? get port => _server?.port;
  List<CharacterSheet> get sheets =>
      _sheets.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  bool isOnline(String playerId) => _online.contains(playerId);

  /// Loads the saved campaign and starts listening for players.
  /// Pass port 0 to let the OS pick one (used in tests).
  Future<void> start({String? name, int port = defaultPort}) async {
    if (isRunning) return;
    final saved = await store.read(_storeKey);
    if (saved != null) {
      sessionName = saved['sessionName'] as String? ?? sessionName;
      for (final s in (saved['sheets'] as List? ?? const [])) {
        final sheet = CharacterSheet.fromJson(s as Map<String, dynamic>);
        _sheets[sheet.id] = sheet;
      }
    }
    if (name != null && name.trim().isNotEmpty) sessionName = name.trim();

    final server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    _server = server;
    server.listen(_onRequest);
    await onStarted?.call(sessionName, server.port);
    await _save();
    notifyListeners();
  }

  Future<void> stop() async {
    await onStopped?.call();
    for (final c in List.of(_clients)) {
      await c.socket.close();
    }
    _clients.clear();
    _online.clear();
    await _server?.close(force: true);
    _server = null;
    notifyListeners();
  }

  /// GM edits a sheet (deal damage, fix a stat...). Pushed to everyone.
  void updateSheet(CharacterSheet sheet) {
    _sheets[sheet.id] = sheet;
    _broadcast(SheetChangedMessage(sheet));
    _save();
    notifyListeners();
  }

  void removeSheet(String id) {
    _sheets.remove(id);
    _save();
    notifyListeners();
  }

  Future<void> _onRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('Op.ez host "$sessionName" (protocol v$protocolVersion)');
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    socket.pingInterval = const Duration(seconds: 5);
    final client = _Client(socket);
    _clients.add(client);
    socket.listen(
      (data) {
        if (data is! String) return;
        try {
          _onMessage(client, Message.decode(data));
        } on Object catch (e) {
          client.send(ErrorMessage('Bad message: $e'));
        }
      },
      onDone: () => _onDisconnect(client),
      onError: (_) => _onDisconnect(client),
      cancelOnError: true,
    );
  }

  void _onMessage(_Client client, Message message) {
    switch (message) {
      case HelloMessage():
        client.playerId = message.playerId;
        client.role = message.role;
        CharacterSheet? sheet;
        if (message.role == ClientRole.player) {
          final stored = _sheets[message.playerId];
          final incoming = message.sheet;
          if (stored == null) {
            sheet = incoming ?? GameRules.newSheet(id: message.playerId, name: message.playerName);
          } else if (incoming != null && incoming.updatedAt > stored.updatedAt) {
            sheet = incoming;
          } else {
            sheet = stored;
          }
          _sheets[sheet.id] = sheet;
          _online.add(message.playerId);
          _broadcast(PlayerStatusMessage(playerId: message.playerId, online: true), except: client);
          _broadcast(SheetChangedMessage(sheet), except: client);
          _save();
        }
        client.send(WelcomeMessage(sessionName: sessionName, sheet: sheet, party: sheets));
        notifyListeners();
      case SheetUpdateMessage():
        final id = client.playerId;
        if (id == null || client.role != ClientRole.player || message.sheet.id != id) {
          client.send(const ErrorMessage('You can only update your own sheet'));
          return;
        }
        _sheets[id] = message.sheet;
        _broadcast(SheetChangedMessage(message.sheet), except: client);
        _save();
        notifyListeners();
      default:
        client.send(ErrorMessage('Unexpected message: ${message.type}'));
    }
  }

  void _onDisconnect(_Client client) {
    if (!_clients.remove(client)) return;
    final id = client.playerId;
    if (id != null && client.role == ClientRole.player) {
      // Only mark offline if the player has no other live connection.
      if (!_clients.any((c) => c.playerId == id)) {
        _online.remove(id);
        _broadcast(PlayerStatusMessage(playerId: id, online: false));
      }
    }
    notifyListeners();
  }

  void _broadcast(Message message, {_Client? except}) {
    final encoded = message.encode();
    for (final c in _clients) {
      if (c != except && c.playerId != null) c.socket.add(encoded);
    }
  }

  Future<void> _save() => store.write(_storeKey, {
        'sessionName': sessionName,
        'sheets': _sheets.values.map((s) => s.toJson()).toList(),
      });

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
