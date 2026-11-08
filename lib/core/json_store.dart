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

  Future<void> write(String name, Map<String, dynamic> data) async {
    final file = await _file(name);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data), flush: true);
    await tmp.rename(file.path);
  }
}
