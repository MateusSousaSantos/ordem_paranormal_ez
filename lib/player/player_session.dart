import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/json_store.dart';
import '../core/protocol.dart';
import '../game/character_sheet.dart';

enum ConnectionStatus { disconnected, connecting, connected }

/// A player's side of a session. Keeps the player's own sheet saved on the
/// phone, sends every change to the GM host and applies changes the GM makes.
/// Reconnects automatically if the Wi-Fi drops.
class PlayerSession extends ChangeNotifier {
  PlayerSession({required this.store});

  final JsonStore store;
  static const _storeKey = 'player';

  late String playerId;
  String playerName = '';
  CharacterSheet? sheet;
  String? lastHost;
  int lastPort = defaultPort;

  String? sessionName;
  final Map<String, CharacterSheet> party = {};
  final Set<String> onlinePlayers = {};
  ConnectionStatus status = ConnectionStatus.disconnected;
  String? lastError;

  WebSocket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _wantConnected = false;

  Future<void> load() async {
    final saved = await store.read(_storeKey);
    playerId = saved?['playerId'] as String? ?? const Uuid().v4();
    playerName = saved?['playerName'] as String? ?? '';
    lastHost = saved?['lastHost'] as String?;
    lastPort = (saved?['lastPort'] as num?)?.toInt() ?? defaultPort;
    final s = saved?['sheet'];
    if (s != null) sheet = CharacterSheet.fromJson(s as Map<String, dynamic>);
    await _save();
    notifyListeners();
  }

  Future<void> connect({required String host, int port = defaultPort, required String name}) async {
    playerName = name.trim();
    lastHost = host;
    lastPort = port;
    _wantConnected = true;
    _reconnectAttempt = 0;
    await _save();
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

  /// Change the player's own sheet. Saved locally and sent to the GM.
  void updateSheet(CharacterSheet updated) {
    sheet = updated;
    party[updated.id] = updated;
    _save();
    _send(SheetUpdateMessage(updated));
    notifyListeners();
  }

  Future<void> _open() async {
    final host = lastHost;
    if (host == null) return;
    status = ConnectionStatus.connecting;
    lastError = null;
    notifyListeners();
    try {
      final socket = await WebSocket.connect('ws://$host:$lastPort')
          .timeout(const Duration(seconds: 5));
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
        playerId: playerId,
        playerName: playerName,
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
        if (message.sheet != null) sheet = message.sheet;
        status = ConnectionStatus.connected;
        _reconnectAttempt = 0;
        _save();
      case SheetChangedMessage():
        party[message.sheet.id] = message.sheet;
        if (message.sheet.id == playerId) {
          sheet = message.sheet;
          _save();
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

  Future<void> _save() => store.write(_storeKey, {
        'playerId': playerId,
        'playerName': playerName,
        if (lastHost != null) 'lastHost': lastHost,
        'lastPort': lastPort,
        if (sheet != null) 'sheet': sheet!.toJson(),
      });

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
