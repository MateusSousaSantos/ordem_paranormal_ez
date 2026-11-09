import 'package:flutter/material.dart';

import '../core/app_storage.dart';
import '../core/protocol.dart';
import '../discovery/lan_discovery.dart';
import '../game/character_sheet.dart';
import '../player/player_session.dart';
import 'characters_screen.dart';
import 'player_sheet_screen.dart';

/// Player screen: pick a GM session found on the Wi-Fi, or type its address.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _browser = LanBrowser();
  final _session = PlayerSession(store: appStore, library: characterLibrary);
  CharacterSheet? _character;
  final _address = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.wait([
      _session.load(),
      if (!characterLibrary.loaded) characterLibrary.load(),
    ]).then((_) {
      if (!mounted) return;
      final saved = characterLibrary.characters;
      if (saved.length == 1) _character = saved.single;
      if (_session.lastHost != null) {
        _address.text = '${_session.lastHost}:${_session.lastPort}';
      }
      setState(() => _loaded = true);
    });
    _browser.start().catchError((Object e) => debugPrint('mDNS discovery failed: $e'));
  }

  @override
  void dispose() {
    _browser.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _join(String host, int port) async {
    final character = _character;
    if (character == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick a character first')));
      return;
    }
    await _browser.stop();
    await _session.connect(host: host, port: port, character: character);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PlayerSheetScreen(session: _session)),
    );
  }

  Future<void> _pickCharacter() async {
    final picked = await Navigator.push<CharacterSheet>(
      context,
      MaterialPageRoute(builder: (_) => const CharactersScreen(pickMode: true)),
    );
    if (picked != null) setState(() => _character = picked);
  }

  void _joinManual() {
    final parts = _address.text.trim().split(':');
    if (parts.first.isEmpty) return;
    final port = parts.length > 1 ? int.tryParse(parts[1]) ?? defaultPort : defaultPort;
    _join(parts.first, port);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Join a session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge),
              title: Text(_character?.name ?? 'Pick a character'),
              subtitle: Text(_character == null
                  ? 'Choose or create the character you will play'
                  : 'Nível ${_character!.nivel} · ${_character!.perfil.label}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCharacter,
            ),
          ),
          const SizedBox(height: 24),
          Text('Sessions on this Wi-Fi', style: Theme.of(context).textTheme.titleMedium),
          ListenableBuilder(
            listenable: _browser,
            builder: (context, _) {
              final hosts = _browser.hosts;
              if (hosts.isEmpty) {
                return const ListTile(
                  leading: SizedBox.square(
                      dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  title: Text('Looking for the GM...'),
                );
              }
              return Column(
                children: [
                  for (final h in hosts)
                    ListTile(
                      leading: const Icon(Icons.wifi_tethering),
                      title: Text(h.name),
                      subtitle: Text('${h.address}:${h.port}'),
                      onTap: () => _join(h.address, h.port),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Or type the address shown on the GM screen',
              style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _address,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(hintText: '192.168.0.10:$defaultPort'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _joinManual, child: const Text('Join')),
            ],
          ),
        ],
      ),
    );
  }
}
