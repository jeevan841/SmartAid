import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreParser {
  /// Safely parse a date that might be a Timestamp, String, or epoch int.
  static DateTime? parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null; // Graceful failure
  }

  /// Safely parse a string.
  static String? parseString(dynamic val) {
    if (val == null) return null;
    return val.toString();
  }

  /// Safely parse an array that should exclusively contain Strings.
  static List<String> parseStringList(dynamic val) {
    if (val == null || val is! Iterable) return [];
    return val.map((e) => e.toString()).toList();
  }

  /// Safely parse an integer from various legacy types.
  static int parseInt(dynamic val, {int defaultValue = 0}) {
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }
  
  /// Safely parse a boolean from various legacy types.
  static bool parseBool(dynamic val, {bool defaultValue = false}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    if (val is num) return val > 0;
    return defaultValue;
  }
}
