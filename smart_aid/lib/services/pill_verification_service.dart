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

    final allText = recognized.blocks
        .map((b) => b.text)
        .join(' ')
        .toLowerCase();

    final expectedLower = expectedMedName.toLowerCase();

    // Fuzzy match: check if the expected name appears in scanned text
    final isMatch =
        allText.contains(expectedLower) ||
        _fuzzyContains(allText, expectedLower);

    return PillScanResult(
      scannedText: allText,
      expectedName: expectedMedName,
      isMatch: isMatch,
    );
  }

  // Simple fuzzy: checks for all significant words in the med name
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
