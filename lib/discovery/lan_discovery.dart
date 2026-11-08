import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

import '../core/protocol.dart';

/// Announces the GM's session on the Wi-Fi via mDNS so players can find it.
class LanAdvertiser {
  BonsoirBroadcast? _broadcast;

  Future<void> start({required String sessionName, required int port}) async {
    await stop();
    final service = BonsoirService(
      name: sessionName,
      type: serviceType,
      port: port,
      attributes: {'v': '$protocolVersion'},
    );
    final broadcast = BonsoirBroadcast(service: service);
    await broadcast.initialize();
    await broadcast.start();
    _broadcast = broadcast;
  }

  Future<void> stop() async {
    await _broadcast?.stop();
    _broadcast = null;
  }
}

class FoundHost {
  const FoundHost({required this.name, required this.address, required this.port});

  final String name;
  final String address;
  final int port;
}

/// Lists GM sessions announced on the Wi-Fi.
class LanBrowser extends ChangeNotifier {
  BonsoirDiscovery? _discovery;
  final Map<String, FoundHost> _hosts = {};

  List<FoundHost> get hosts => _hosts.values.toList();

  Future<void> start() async {
    await stop();
    final discovery = BonsoirDiscovery(type: serviceType);
    await discovery.initialize();
    discovery.eventStream?.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent():
          event.service.resolve(discovery.serviceResolver);
        case BonsoirDiscoveryServiceResolvedEvent():
          _add(event.service);
        case BonsoirDiscoveryServiceUpdatedEvent():
          _add(event.service);
        case BonsoirDiscoveryServiceLostEvent():
          if (_hosts.remove(event.service.name) != null) notifyListeners();
        default:
          break;
      }
    });
    await discovery.start();
    _discovery = discovery;
  }

  void _add(BonsoirService s) {
    // Prefer IPv4: easier to read and to type by hand.
    final address =
        s.hostAddresses.where((a) => !a.contains(':')).firstOrNull ?? s.hostAddress;
    if (address == null) return;
    _hosts[s.name] = FoundHost(name: s.name, address: address, port: s.port);
    notifyListeners();
  }

  Future<void> stop() async {
    await _discovery?.stop();
    _discovery = null;
    _hosts.clear();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
