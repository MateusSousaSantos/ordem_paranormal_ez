import 'dart:convert';
import 'dart:io';

/// Saves small JSON documents as files in one directory.
class JsonStore {
  JsonStore(this._directory);

  final Future<Directory> Function() _directory;

  Future<File> _file(String name) async => File('${(await _directory()).path}/$name.json');

  Future<Map<String, dynamic>?> read(String name) async {
    final file = await _file(name);
    if (!await file.exists()) return null;
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  /// Writes run one after another: two overlapping writes to the same
  /// document would otherwise race on the same temp file.
  Future<void> _queue = Future.value();

  Future<void> write(String name, Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    final next = _queue.then((_) async {
      final file = await _file(name);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(encoded, flush: true);
      await tmp.rename(file.path);
    });
    _queue = next.catchError((Object _) {});
    return next;
  }
}
