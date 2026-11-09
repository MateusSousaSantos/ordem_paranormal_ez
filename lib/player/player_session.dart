import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/json_store.dart';
import '../core/protocol.dart';
import '../game/character_library.dart';
import '../game/character_sheet.dart';

enum ConnectionStatus { disconnected, connecting, connected }

/// A player's side of a session, playing one character from their
/// [CharacterLibrary]. Every change is saved on the phone, sent to the GM
/// host, and changes the GM makes are applied back. Reconnects automatically
/// if the Wi-Fi drops.
class PlayerSession extends ChangeNotifier {
  PlayerSession({required this.store, required this.library});

  final JsonStore store;
  final CharacterLibrary library;
  static const _storeKey = 'last_host';

  String? lastHost;
  int lastPort = defaultPort;

  /// The character being played. Its id identifies the player to the host.
  CharacterSheet? sheet;

  String? sessionName;
  final Map<String, CharacterSheet> party = {};
  final Set<String> onlinePlayers = {};
  ConnectionStatus status = ConnectionStatus.disconnected;
  String? lastError;

  WebSocket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _wantConnected = false;

  /// Loads the last host address used, to prefill the join screen.
  Future<void> load() async {
    final saved = await store.read(_storeKey);
    lastHost = saved?['host'] as String?;
    lastPort = (saved?['port'] as num?)?.toInt() ?? defaultPort;
    notifyListeners();
  }

  Future<void> connect({
    required String host,
    int port = defaultPort,
    required CharacterSheet character,
  }) async {
    sheet = character;
    lastHost = host;
    lastPort = port;
    _wantConnected = true;
    _reconnectAttempt = 0;
    await store.write(_storeKey, {'host': host, 'port': port});
    await _open();
  }

  Future<void> disconnect() async {
    _wantConnected = false;
    _reconnectTimer?.cancel();
    await _socket?.close();
    _socket = null;
    status = ConnectionStatus.disconnected;
    notifyListeners();
  }

  /// Change the character. Saved locally and sent to the GM.
  void updateSheet(CharacterSheet updated) {
    _apply(updated);
    _send(SheetUpdateMessage(updated));
    notifyListeners();
  }

  void _apply(CharacterSheet updated) {
    sheet = updated;
    party[updated.id] = updated;
    library.save(updated);
  }

  Future<void> _open() async {
    final host = lastHost;
    final character = sheet;
    if (host == null || character == null) return;
    status = ConnectionStatus.connecting;
    lastError = null;
    notifyListeners();
    try {
      final socket =
          await WebSocket.connect('ws://$host:$lastPort').timeout(const Duration(seconds: 5));
      socket.pingInterval = const Duration(seconds: 5);
      _socket = socket;
      socket.listen(
        (data) {
          if (data is String) _onMessage(Message.decode(data));
        },
        onDone: _onClosed,
        onError: (_) => _onClosed(),
        cancelOnError: true,
      );
      socket.add(HelloMessage(
        playerId: character.id,
        playerName: character.name,
        sheet: sheet,
      ).encode());
    } on Object catch (e) {
      lastError = '$e';
      _onClosed();
    }
  }

  void _onMessage(Message message) {
    switch (message) {
      case WelcomeMessage():
        sessionName = message.sessionName;
        party
          ..clear()
          ..addEntries(message.party.map((s) => MapEntry(s.id, s)));
        if (message.sheet != null) _apply(message.sheet!);
        status = ConnectionStatus.connected;
        _reconnectAttempt = 0;
      case SheetChangedMessage():
        if (message.sheet.id == sheet?.id) {
          _apply(message.sheet);
        } else {
          party[message.sheet.id] = message.sheet;
        }
      case PlayerStatusMessage():
        message.online
            ? onlinePlayers.add(message.playerId)
            : onlinePlayers.remove(message.playerId);
      case ErrorMessage():
        lastError = message.message;
      default:
        break;
    }
    notifyListeners();
  }

  void _onClosed() {
    _socket = null;
    status = ConnectionStatus.disconnected;
    notifyListeners();
    if (!_wantConnected) return;
    // Back off 1s, 2s, 4s... up to 15s between attempts.
    final delay = Duration(seconds: (1 << _reconnectAttempt).clamp(1, 15));
    _reconnectAttempt = (_reconnectAttempt + 1).clamp(0, 4);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _open);
  }

  void _send(Message m) {
    if (status == ConnectionStatus.connected) _socket?.add(m.encode());
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    disconnect();
    super.dispose();
  }
}
