import 'package:path_provider/path_provider.dart';

import '../game/character_library.dart';
import 'json_store.dart';

/// Store backed by the app's private documents folder on the device.
final appStore = JsonStore(getApplicationDocumentsDirectory);

/// Characters saved on this phone. Call `load()` before first use.
final characterLibrary = CharacterLibrary(store: appStore);
