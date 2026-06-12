import 'package:flutter/foundation.dart';

class SecureLogger {
  static void log(String message) {
    if (kReleaseMode) {
      // In production, we explicitly swallow standard logs to prevent PII leakage.
      return;
    }
    debugPrint('[SecureLogger] $message');
  }

  static void logError(String context, Object error, {StackTrace? stackTrace}) {
    if (kReleaseMode) {
      // In production, redact the error payload. Do not print stack traces.
      debugPrint('[SecureError] $context: <Redacted payload>');
      return;
    }
    debugPrint('[SecureError] $context: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  /// Explicitly used to ensure AI prompts and Sync payloads are NEVER logged raw.
  static void logSensitive(String context) {
    if (kReleaseMode) return;
    debugPrint('[SecureSensitive] $context: <Content Redacted>');
  }
}
