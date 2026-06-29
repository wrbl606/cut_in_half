import 'dart:js_interop';

/// Web [LocalStore] backed by `window.localStorage`.
///
/// `dart:io` File and path_provider's `getApplicationSupportDirectory` are
/// unsupported on Flutter Web, so persistence is routed through the browser's
/// `localStorage` (which only holds strings — exactly what the JSON-encoded
/// services store). Values survive page reloads for the origin.
@JS('localStorage.getItem')
external JSString? _localStorageGetItem(JSString key);

@JS('localStorage.setItem')
external void _localStorageSetItem(JSString key, JSString value);

class LocalStore {
  /// Returns the stored string for [key], or `null` if absent.
  Future<String?> read(String key) async {
    final value = _localStorageGetItem(key.toJS);
    return value?.toDart;
  }

  /// Writes [value] for [key], creating or overwriting the stored entry.
  Future<void> write(String key, String value) async {
    _localStorageSetItem(key.toJS, value.toJS);
  }
}
