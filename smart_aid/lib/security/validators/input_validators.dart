class InputValidators {
  /// Mitigates HTML injection, prompt injection, and excessive payload sizes.
  static String sanitizeText(String? input, {int maxLength = 200, String fallback = 'Unknown'}) {
    if (input == null || input.trim().isEmpty) return fallback;
    
    // 1. Truncate to deterministic bounds
    String sanitized = input.trim();
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    // 2. Strip basic HTML/script tags aggressively
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 3. Mitigate prompt injection patterns (system markers)
    sanitized = sanitized.replaceAll(RegExp(r'systemInstruction|System:|Instruction:', caseSensitive: false), '[REDACTED]');

    return sanitized;
  }
  
  /// Validates basic alphanumeric/dash IDs to prevent path traversal or injection
  static bool isValidId(String? id) {
    if (id == null || id.isEmpty || id.length > 100) return false;
    return RegExp(r'^[\w\-]+$').hasMatch(id);
  }
}
