import 'dart:io';
import 'package:examis_ai/core/secrets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExportService {
  Future<bool> exportToWord(
      Map<String, dynamic> data,
      String templateUrl,
      bool showCloTags,
      ) async {
    try {
      final apiUrl = Uri.parse(AppSecrets.documentAPI_KEY);

      final payload = {
        "template_url": templateUrl,
        "show_clo_tags": showCloTags,
        "exam_data": {
          "title": data['title'] ?? "Assessment",
          "marks":
          data['marks'] ??
              {
                "mcq_points": 1,
                "short_points": 3,
                "long_points": 10,
                "fib_points": 1,
              },
          "custom_scenarios": data['custom_scenarios'] ?? [],
          "mcqs": data['mcqs'] ?? [],
          "shortQuestions": data['shortQuestions'] ?? [],
          "longQuestions": data['longQuestions'] ?? [],
          "fillInTheBlanks": data['fillInTheBlanks'] ?? [],

          // 👇 THE MISSING PIECE! 👇
          "diagram_questions": data['diagram_questions'] ?? [],
        },
      };

      print("Sending data to Python API...");

      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final title = data['title'] ?? "Assessment";
        final output = await getTemporaryDirectory();
        final String filePath =
            "${output.path}/${title.replaceAll(' ', '_')}.docx";
        final file = File(filePath);

        await file.writeAsBytes(bytes);

        final params = ShareParams(
          files: [XFile(filePath)],
          text: 'Here is the generated Word Document!',
        );
        await SharePlus.instance.share(params);
        return true;
      } else {
        print("API Error: ${response.statusCode}");
        print("API Message: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Word Export Network Error: $e");
      return false;
    }
  }
}