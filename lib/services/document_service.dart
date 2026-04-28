import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/material.dart';

class DocumentService {
  Future<String?> extractTextFromPDF(String filePath) async {
    try {
      File file = File(filePath);
      final PdfDocument document = PdfDocument(
        inputBytes: await file.readAsBytes(),
      );
      String extractedText = PdfTextExtractor(document).extractText();
      document.dispose();

      if (extractedText.trim().isEmpty) return null;

      if (extractedText.length > 15000) {
        extractedText = extractedText.substring(0, 15000);
      }

      return extractedText;
    } catch (e) {
      debugPrint("Failed to extract text: $e");
      return null;
    }
  }
}
