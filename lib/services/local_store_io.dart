import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File-based [LocalStore] for platforms that support `dart:io`.
///
/// Each key maps to a JSON file named `key` inside the application support
/// directory. This preserves the original mobile/desktop persistence
/// behaviour.
class LocalStore {
  Future<File> _file(String key) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$key');
  }

  /// Returns the stored string for [key], or `null` if absent.
  Future<String?> read(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// Writes [value] for [key], creating or overwriting the backing file.
  Future<void> write(String key, String value) async {
    final file = await _file(key);
    await file.writeAsString(value, flush: true);
  }
}
