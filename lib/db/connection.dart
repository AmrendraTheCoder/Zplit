// Platform-specific database connection.
//
// Uses conditional imports to provide the right database backend:
// NativeDatabase for mobile/desktop, WebDatabase for Chrome/web.
import 'database.dart';

// Conditional import: picks the right implementation
import 'connection/native.dart' if (dart.library.html) 'connection/web.dart'
    as platform;

ZplitDatabase constructDb() {
  return ZplitDatabase(platform.connect());
}
