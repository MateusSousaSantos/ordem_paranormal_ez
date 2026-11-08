import 'package:flutter/material.dart';

import '../player/player_session.dart';
import 'widgets/sheet_view.dart';

/// The player's own sheet, synced live with the GM.
class PlayerSheetScreen extends StatefulWidget {
  const PlayerSheetScreen({super.key, required this.session});

  final PlayerSession session;

  @override
  State<PlayerSheetScreen> createState() => _PlayerSheetScreenState();
}

class _PlayerSheetScreenState extends State<PlayerSheetScreen> {
  @override
  void dispose() {
    widget.session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final sheet = session.sheet;
        return Scaffold(
          appBar: AppBar(
            title: Text(session.sessionName ?? 'Connecting...'),
            actions: [_StatusIcon(status: session.status)],
          ),
          body: sheet == null
              ? Center(
                  child: Text(session.lastError ?? 'Waiting for the GM...',
                      textAlign: TextAlign.center),
                )
              : SheetView(sheet: sheet, onChanged: session.updateSheet),
        );
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, tip) = switch (status) {
      ConnectionStatus.connected => (Icons.wifi, Colors.green, 'Connected to GM'),
      ConnectionStatus.connecting => (Icons.wifi_find, Colors.amber, 'Connecting...'),
      ConnectionStatus.disconnected => (Icons.wifi_off, Colors.red, 'Offline, reconnecting'),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(message: tip, child: Icon(icon, color: color)),
    );
  }
}
