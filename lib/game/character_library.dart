import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/json_store.dart';
import 'character_sheet.dart';

/// The characters a player has saved on this phone.
class CharacterLibrary extends ChangeNotifier {
  CharacterLibrary({required this.store});

  final JsonStore store;
  static const _storeKey = 'characters';

  final Map<String, CharacterSheet> _characters = {};
  bool loaded = false;

  List<CharacterSheet> get characters =>
      _characters.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  CharacterSheet? byId(String id) => _characters[id];

  Future<void> load() async {
    final saved = await store.read(_storeKey);
    _characters.clear();
    for (final c in (saved?['characters'] as List? ?? const [])) {
      final sheet = CharacterSheet.fromJson(c as Map<String, dynamic>);
      _characters[sheet.id] = sheet;
    }
    loaded = true;
    notifyListeners();
  }

  CharacterSheet create() => GameRules.newSheet(id: const Uuid().v4());

  Future<void> save(CharacterSheet sheet) async {
    _characters[sheet.id] = sheet;
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _characters.remove(id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => store.write(_storeKey, {
        'characters': _characters.values.map((c) => c.toJson()).toList(),
      });
}
