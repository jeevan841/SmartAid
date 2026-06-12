class InputValidators {
  /// Mitigates HTML injection, prompt injection, and excessive payload sizes.
  /// Order: strip tags FIRST → mitigate prompt injection → THEN truncate on word boundary.
  static String sanitizeText(String? input, {int maxLength = 200, String fallback = 'Unknown'}) {
    if (input == null || input.trim().isEmpty) return fallback;

    String sanitized = input.trim();

    // 1. Strip HTML/script tags BEFORE truncating, so a tag spanning the cut point isn't left open
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');

    // 2. Mitigate prompt injection patterns (system markers)
    sanitized = sanitized.replaceAll(
      RegExp(r'systemInstruction|System:|Instruction:', caseSensitive: false),
      '[REDACTED]',
    );

    // 3. Truncate AFTER sanitizing, on a word boundary where possible
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
      // Avoid cutting mid-word — trim back to the last space if it's past the halfway mark
      final lastSpace = sanitized.lastIndexOf(' ');
      if (lastSpace > maxLength ~/ 2) {
        sanitized = sanitized.substring(0, lastSpace);
      }
    }

    return sanitized.trim();
  }

  /// Validates basic alphanumeric/dash IDs to prevent path traversal or injection
  static bool isValidId(String? id) {
    if (id == null || id.isEmpty || id.length > 100) return false;
    return RegExp(r'^[\w\-]+$').hasMatch(id);
  }
}
