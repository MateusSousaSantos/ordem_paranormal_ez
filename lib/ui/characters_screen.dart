import 'package:flutter/material.dart';

import '../core/app_storage.dart';
import '../game/character_sheet.dart';
import 'character_edit_screen.dart';

/// The characters saved on this phone. With [pickMode], tapping a character
/// returns it (used when joining a session) instead of opening the editor.
class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  final _library = characterLibrary;

  @override
  void initState() {
    super.initState();
    if (!_library.loaded) _library.load();
  }

  Future<CharacterSheet?> _edit(CharacterSheet sheet) => Navigator.push<CharacterSheet>(
        context,
        MaterialPageRoute(builder: (_) => CharacterEditScreen(library: _library, initial: sheet)),
      );

  Future<void> _create() async {
    final created = await _edit(_library.create());
    if (created != null && widget.pickMode && mounted) Navigator.pop(context, created);
  }

  Future<void> _delete(CharacterSheet sheet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apagar ${sheet.name}?'),
        content: const Text('Isso não pode ser desfeito.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok == true) await _library.delete(sheet.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pickMode ? 'Escolha um personagem' : 'Meus personagens')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: ListenableBuilder(
        listenable: _library,
        builder: (context, _) {
          if (!_library.loaded) return const Center(child: CircularProgressIndicator());
          final characters = _library.characters;
          if (characters.isEmpty) {
            return const Center(child: Text('Nenhum personagem ainda. Toque em "Novo".'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final c in characters)
                ListTile(
                  leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name[0])),
                  title: Text(c.name),
                  subtitle: Text(
                      'Nível ${c.nivel} · ${c.perfil.label}${c.vocacao.isEmpty ? '' : ' · ${c.vocacao}'}'),
                  onTap: () => widget.pickMode ? Navigator.pop(context, c) : _edit(c),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? _edit(c) : _delete(c),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Apagar')),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
