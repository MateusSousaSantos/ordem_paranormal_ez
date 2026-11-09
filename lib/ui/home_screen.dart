import 'package:flutter/material.dart';

import 'characters_screen.dart';
import 'gm_dashboard_screen.dart';
import 'join_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Op.ez', style: theme.textTheme.displayMedium, textAlign: TextAlign.center),
              Text('Ordem Paranormal EZ',
                  style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Host a session (GM)'),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const GmDashboardScreen())),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Join as player'),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinScreen())),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.badge),
                label: const Text('My characters'),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const CharactersScreen())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
