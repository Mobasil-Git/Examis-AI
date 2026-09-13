import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class DocumentRepository {
  final String _extractUrl = dotenv.env['DOCUMENT_EXTRACTION_API_KEY']!;

  Future<String?> extractTextFromFiles(List<PlatformFile> files) async {
    var request = http.MultipartRequest('POST', Uri.parse(_extractUrl));

    for (var file in files) {
      if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('files', file.path!),
        );
      }
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['extracted_text'];
      } else {
        throw Exception("Python Extraction Error: ${jsonResponse['error']}");
      }
    } else {
      throw Exception("Server Error: ${response.statusCode}");
    }
  }
}