import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class DocumentService {
  final String _extractUrl = 'https://examis-text-extractor.vercel.app/extract-text';

  Future<String?> extractTextFromFiles(List<PlatformFile> files) async {
    try {
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
          print("Python Extraction Error: ${jsonResponse['error']}");
          return null;
        }
      } else {
        print("Server Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Network Error sending files: $e");
      return null;
    }
  }
}