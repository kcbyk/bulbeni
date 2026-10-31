import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final OcrService instance = OcrService._internal();
  OcrService._internal();

  TextRecognizer? _textRecognizer;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Extracts text from an image file at [imagePath].
  /// Uses ML Kit on mobile devices (Android/iOS).
  /// Provides safe desktop fallback so it runs smoothly everywhere.
  Future<String> recognizeText(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return '';
    }

    // Check platform support for ML Kit native recognition
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final inputImage = InputImage.fromFilePath(imagePath);
        final recognizedText = await textRecognizer.processImage(inputImage);
        return recognizedText.text.trim();
      } catch (e) {
        debugPrint('ML Kit recognition error: $e');
        // Graceful fallback if ML Kit model is downloading or encountering issues
        return _fallbackTextExtraction(file);
      }
    } else {
      // Desktop or testing environment fallback
      return _fallbackTextExtraction(file);
    }
  }

  /// Fallback extraction when ML Kit native library is not available (e.g. Windows desktop preview)
  String _fallbackTextExtraction(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    return 'Görsel içeriği: $fileName (Yerel indeks)';
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
