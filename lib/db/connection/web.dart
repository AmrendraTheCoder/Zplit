// ignore_for_file: deprecated_member_use
import 'package:drift/web.dart';

/// Web database connection using IndexedDB-backed storage.
/// Uses drift/web.dart for broad browser compatibility.
WebDatabase connect() {
  return WebDatabase('zplit_db');
}
