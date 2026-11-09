import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../core/app_storage.dart';
import '../discovery/lan_discovery.dart';
import '../game/character_sheet.dart';
import '../host/host_session.dart';
import 'widgets/sheet_view.dart';

/// GM screen: hosts the session and shows every player's sheet live.
class GmDashboardScreen extends StatefulWidget {
  const GmDashboardScreen({super.key});

  @override
  State<GmDashboardScreen> createState() => _GmDashboardScreenState();
}

class _GmDashboardScreenState extends State<GmDashboardScreen> {
  final _advertiser = LanAdvertiser();
  late final HostSession _host = HostSession(
    store: appStore,
    onStarted: (name, port) => _advertiser
        .start(sessionName: name, port: port)
        .catchError((Object e) => debugPrint('mDNS broadcast failed: $e')),
    onStopped: _advertiser.stop,
  );
  String? _ip;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await _host.start();
      final ip = await NetworkInfo().getWifiIP();
      if (mounted) setState(() => _ip = ip);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _host,
      builder: (context, _) {
        final sheets = _host.sheets;
        return Scaffold(
          appBar: AppBar(
            title: Text(_host.sessionName),
            actions: [
              IconButton(
                tooltip: 'Rename session',
                icon: const Icon(Icons.edit),
                onPressed: _rename,
              ),
            ],
          ),
          body: Column(
            children: [
              _HostBanner(running: _host.isRunning, ip: _ip, port: _host.port, error: _error),
              Expanded(
                child: sheets.isEmpty
                    ? const Center(child: Text('Waiting for players to join...'))
                    : ListView(
                        children: [
                          for (final s in sheets)
                            _PlayerTile(
                              sheet: s,
                              online: _host.isOnline(s.id),
                              onTap: () => _openSheet(s.id),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _host.sessionName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await _host.stop();
    await _host.start(name: name);
  }

  void _openSheet(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListenableBuilder(
          listenable: _host,
          builder: (context, _) {
            final sheet = _host.sheets.where((s) => s.id == id).firstOrNull;
            return Scaffold(
              appBar: AppBar(title: Text(sheet?.name ?? 'Player left')),
              body: sheet == null
                  ? const SizedBox()
                  : SheetView(sheet: sheet, onChanged: _host.updateSheet),
            );
          },
        ),
      ),
    );
  }
}

class _HostBanner extends StatelessWidget {
  const _HostBanner({required this.running, this.ip, this.port, this.error});

  final bool running;
  final String? ip;
  final int? port;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = error != null
        ? 'Could not start: $error'
        : !running
            ? 'Starting...'
            : 'Players on this Wi-Fi can join. Address: ${ip ?? 'unknown'}:$port';
    return Container(
      width: double.infinity,
      color: error != null ? scheme.errorContainer : scheme.secondaryContainer,
      padding: const EdgeInsets.all(12),
      child: Text(text),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.sheet, required this.online, required this.onTap});

  final CharacterSheet sheet;
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = 'PV ${sheet.pv.current}/${sheet.pv.max}   '
        'PD ${sheet.pd.current}/${sheet.pd.max}   Nível ${sheet.nivel}';
    return ListTile(
      leading: Icon(Icons.circle, size: 12, color: online ? Colors.green : Colors.grey),
      title: Text(sheet.name),
      subtitle: Text(summary),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
