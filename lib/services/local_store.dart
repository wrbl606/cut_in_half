/// Platform-conditional key/value string store used by [StorageService] and
/// [AttemptStore].
///
/// On platforms that have `dart:io` (mobile/desktop) the file-based
/// implementation from `local_store_io.dart` is used, preserving the
/// existing path_provider-backed persistence. On the web `dart:io` is
/// unavailable, so the `local_store_web.dart` implementation — backed by
/// `window.localStorage` via `dart:js_interop` — is selected instead.
///
/// Both implementations expose the same public `read`/`write` API.
library;

export 'local_store_web.dart' // default: web (no dart:io)
    if (dart.library.io) 'local_store_io.dart';
