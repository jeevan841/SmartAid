// lib/services/pill_verification_service.dart

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class PillVerificationService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _picker = ImagePicker();

  Future<PillScanResult> scanAndVerify(String expectedMedName) async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return PillScanResult.cancelled();

    final inputImage = InputImage.fromFilePath(image.path);
    final recognized = await _textRecognizer.processImage(inputImage);

    // Collect raw text (preserve case for best-guess name extraction)
    final rawText = recognized.blocks.map((b) => b.text).join(' ');

    // Clean the OCR output into a usable drug name
    final cleanedName = cleanMedicationName(rawText);

    // Lowercase version for matching
    final lowerClean = cleanedName.toLowerCase();
    final expectedLower = expectedMedName.toLowerCase();

    final isMatch = lowerClean.contains(expectedLower) ||
        _fuzzyContains(lowerClean, expectedLower);

    return PillScanResult(
      scannedText: cleanedName,
      expectedName: expectedMedName,
      isMatch: isMatch,
    );
  }

  /// Cleans garbled OCR output into a usable medication name.
  ///
  /// Handles common ML Kit artifacts such as:
  ///   - Pipe characters:  `methyl||prop`  → `methylprop`
  ///   - Broken hyphens:   `meth- ylprop` → `methylprop`
  ///   - Leading digits:   `5 mi hrog`    → `hrog`
  ///   - Special noise:    `@#$%`         → stripped
  ///   - Excess whitespace / punctuation
  static String cleanMedicationName(String raw) {
    var text = raw;

    // 1. Remove pipe characters (common OCR artifact for 'l' / 'I')
    text = text.replaceAll(RegExp(r'\|+'), '');

    // 2. Fix broken hyphenation: "meth- ylprop" → "methylprop"
    text = text.replaceAll(RegExp(r'-\s+'), '');

    // 3. Strip characters that are never in a drug name
    text = text.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\(\)\.]'), '');

    // 4. Remove leading standalone numbers / dosage noise e.g. "5 mg 250ml"
    text = text.replaceAll(
        RegExp(r'^\s*[\d]+\s*(mg|ml|mcg|g|iu|%)?\s*', caseSensitive: false), '');

    // 5. Remove leftover standalone numbers in the middle
    text = text.replaceAll(RegExp(r'\b\d+\b'), '');

    // 6. Collapse multiple spaces
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    // 7. Title-case the result for a clean display name
    if (text.isEmpty) return raw.trim(); // fallback if cleanup removed everything
    return text
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  // Simple fuzzy: checks if all significant words of the expected name appear
  bool _fuzzyContains(String haystack, String needle) {
    final words = needle.split(' ').where((w) => w.length > 3).toList();
    if (words.isEmpty) return false;
    return words.every((word) => haystack.contains(word));
  }

  void dispose() => _textRecognizer.close();
}

class PillScanResult {
  final String? scannedText;
  final String? expectedName;
  final bool isMatch;
  final bool cancelled;

  PillScanResult({
    required this.scannedText,
    required this.expectedName,
    required this.isMatch,
  }) : cancelled = false;

  PillScanResult.cancelled()
      : scannedText = null,
        expectedName = null,
        isMatch = false,
        cancelled = true;
}
