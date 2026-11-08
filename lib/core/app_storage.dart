import 'package:path_provider/path_provider.dart';

import 'json_store.dart';

/// Store backed by the app's private documents folder on the device.
final appStore = JsonStore(getApplicationDocumentsDirectory);
