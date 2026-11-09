import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../player/player_session.dart';
import 'theme/sheet_style.dart';
import 'widgets/in_session_sheet.dart';

/// The player's own sheet during a session, in landscape, synced with the GM.
class PlayerSheetScreen extends StatefulWidget {
  const PlayerSheetScreen({super.key, required this.session});

  final PlayerSession session;

  @override
  State<PlayerSheetScreen> createState() => _PlayerSheetScreenState();
}

class _PlayerSheetScreenState extends State<PlayerSheetScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    widget.session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      backgroundColor: SheetStyle.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final sheet = session.sheet;
            if (sheet == null) {
              return Center(
                child: Text(session.lastError ?? 'Esperando o mestre...',
                    style: SheetStyle.mono(13), textAlign: TextAlign.center),
              );
            }
            return InSessionSheet(
              sheet: sheet,
              onChanged: session.updateSheet,
              onClose: () => Navigator.pop(context),
              statusIcon: _StatusIcon(status: session.status),
            );
          },
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, tip) = switch (status) {
      ConnectionStatus.connected => (Icons.wifi, Colors.greenAccent, 'Conectado ao mestre'),
      ConnectionStatus.connecting => (Icons.wifi_find, Colors.amber, 'Conectando...'),
      ConnectionStatus.disconnected => (Icons.wifi_off, Colors.redAccent, 'Offline, reconectando'),
    };
    return Tooltip(message: tip, child: Icon(icon, color: color, size: 20));
  }
}
