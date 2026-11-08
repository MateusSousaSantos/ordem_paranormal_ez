import 'dart:convert';

import '../game/character_sheet.dart';

/// Wire protocol between the GM host and its clients (players now, the
/// online table later). Every message is one JSON object sent as a WebSocket
/// text frame, with a "type" field.
///
/// Client -> host:
///   hello         {playerId, playerName, role, sheet?}   first message
///   sheet_update  {sheet}                                 player changed their sheet
///
/// Host -> client:
///   welcome       {sessionName, sheet?, party}            reply to hello
///   sheet_changed {sheet}                                 any sheet changed
///   player_status {playerId, online}                      someone (dis)connected
///   error         {message}
///
/// The transport (local WebSocket today, a relay server later) only moves
/// these messages, so remote play can be added without changing this file.
const int protocolVersion = 1;

/// Default TCP port the GM host listens on.
const int defaultPort = 40450;

/// mDNS service type used to find hosts on the Wi-Fi.
const String serviceType = '_opez._tcp';

enum ClientRole {
  /// A player who owns one character sheet.
  player,

  /// Read-only client that receives every update (e.g. the online table).
  observer,
}

sealed class Message {
  const Message();

  String get type;
  Map<String, dynamic> body();

  String encode() => jsonEncode({'type': type, 'v': protocolVersion, ...body()});

  static Message decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final type = json['type'];
    switch (type) {
      case HelloMessage.kType:
        return HelloMessage(
          playerId: json['playerId'] as String,
          playerName: json['playerName'] as String,
          role: ClientRole.values.byName(json['role'] as String? ?? 'player'),
          sheet: _sheetOrNull(json['sheet']),
        );
      case WelcomeMessage.kType:
        return WelcomeMessage(
          sessionName: json['sessionName'] as String,
          sheet: _sheetOrNull(json['sheet']),
          party: (json['party'] as List)
              .map((e) => CharacterSheet.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case SheetUpdateMessage.kType:
        return SheetUpdateMessage(
            CharacterSheet.fromJson(json['sheet'] as Map<String, dynamic>));
      case SheetChangedMessage.kType:
        return SheetChangedMessage(
            CharacterSheet.fromJson(json['sheet'] as Map<String, dynamic>));
      case PlayerStatusMessage.kType:
        return PlayerStatusMessage(
          playerId: json['playerId'] as String,
          online: json['online'] as bool,
        );
      case ErrorMessage.kType:
        return ErrorMessage(json['message'] as String);
      default:
        throw FormatException('Unknown message type: $type');
    }
  }

  static CharacterSheet? _sheetOrNull(Object? json) =>
      json == null ? null : CharacterSheet.fromJson(json as Map<String, dynamic>);
}

class HelloMessage extends Message {
  const HelloMessage({
    required this.playerId,
    required this.playerName,
    this.role = ClientRole.player,
    this.sheet,
  });

  static const kType = 'hello';
  final String playerId;
  final String playerName;
  final ClientRole role;

  /// The player's local copy, so the host can keep whichever is newer.
  final CharacterSheet? sheet;

  @override
  String get type => kType;

  @override
  Map<String, dynamic> body() => {
        'playerId': playerId,
        'playerName': playerName,
        'role': role.name,
        if (sheet != null) 'sheet': sheet!.toJson(),
      };
}

class WelcomeMessage extends Message {
  const WelcomeMessage({required this.sessionName, this.sheet, required this.party});

  static const kType = 'welcome';
  final String sessionName;

  /// The authoritative copy of the joining player's sheet (null for observers).
  final CharacterSheet? sheet;

  /// Every sheet in the session.
  final List<CharacterSheet> party;

  @override
  String get type => kType;

  @override
  Map<String, dynamic> body() => {
        'sessionName': sessionName,
        if (sheet != null) 'sheet': sheet!.toJson(),
        'party': party.map((s) => s.toJson()).toList(),
      };
}

class SheetUpdateMessage extends Message {
  const SheetUpdateMessage(this.sheet);

  static const kType = 'sheet_update';
  final CharacterSheet sheet;

  @override
  String get type => kType;

  @override
  Map<String, dynamic> body() => {'sheet': sheet.toJson()};
}

class SheetChangedMessage extends Message {
  const SheetChangedMessage(this.sheet);

  static const kType = 'sheet_changed';
  final CharacterSheet sheet;

  @override
  String get type => kType;

  @override
  Map<String, dynamic> body() => {'sheet': sheet.toJson()};
}

class PlayerStatusMessage extends Message {
  const PlayerStatusMessage({required this.playerId, required this.online});

  static const kType = 'player_status';
  final String playerId;
  final bool online;

  @override
  String get type => kType;

  @override
  Map<String, dynamic> body() => {'playerId': playerId, 'online': online};
}

class ErrorMessage extends Message {
  const ErrorMessage(this.message);

  static const kType = 'error';
  final String message;

  @override
  String get type => kType;

  @override
  Map<String, dynamic> body() => {'message': message};
}
