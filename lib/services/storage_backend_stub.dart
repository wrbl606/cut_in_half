/// Fallback database backend used when neither a native (io) nor a web
/// (js_interop) backend is selected. In practice every supported target
/// picks one of the conditional implementations; this stub only exists so
/// the dispatcher always resolves [openAppDatabase] on every platform.
library;

import 'package:sembast/sembast.dart';

Future<Database> openAppDatabase(String name) async {
  throw UnsupportedError(
    'No sembast storage backend is available on this platform.',
  );
}