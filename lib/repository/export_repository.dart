import 'dart:io';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExportRepository {
  String _getFullDepartmentName(String shortName) {
    final String cleanName = shortName.trim().toUpperCase();

    final Map<String, String> departmentMap = {
      "CS": "Computing Sciences",
      "IT": "Information Technology",
      "SE": "Software Engineering",
      "AI": "Artificial Intelligence",
      "DS": "Data Science",
      "CYS": "Cyber Security",
      "MATH": "Mathematics",
      "BBA": "Business Administration",
      "ENG": "English",
      "PHY": "Physics",
    };

    return departmentMap[cleanName] ?? shortName;
  }
  Future<bool> exportToWord(
      Map<String, dynamic> data,
      String templateUrl,
      bool showCloTags,
      String examType,
      double totalMarks,
      String courseTitle,
      String creditHours,
      String departmentName,
      ) async {
    try {
      final apiUrl = Uri.parse(dotenv.env['DOCUMENT_API_KEY']!);

      final Map<String, dynamic> marksData = data['marks'] ?? {
        "mcq_points": 1.0,
        "short_points": 3.0,
        "long_points": 10.0,
        "fib_points": 1.0,
      };

      final int mcqCount = (data['mcqs'] as List?)?.length ?? 0;
      final int fibCount = (data['fillInTheBlanks'] as List?)?.length ?? 0;
      final int shortCount = (data['shortQuestions'] as List?)?.length ?? 0;
      final int longCount = (data['longQuestions'] as List?)?.length ?? 0;

      final bool hasObjective = (mcqCount > 0 || fibCount > 0);
      final bool hasSubjective = (shortCount > 0 || longCount > 0);

      String paperType = "Standard";
      if (hasObjective && hasSubjective) {
        paperType = "Subjective + Objective";
      } else if (hasObjective) {
        paperType = "Objective";
      } else if (hasSubjective) {
        paperType = "Subjective";
      }

      // Helper to safely map sub_parts
      List<Map<String, dynamic>> mapSubParts(dynamic item) {
        if (item['sub_parts'] != null && item['sub_parts'] is List) {
          return (item['sub_parts'] as List).map((sp) => {
            "label": sp['label'] ?? "a",
            "question": sp['question'] ?? "",
            "marks": sp['marks'] ?? 0.0,
          }).toList();
        }
        return [];
      }

      final payload = {
        "template_url": templateUrl,
        "show_clo_tags": showCloTags,
        "exam_data": {
          "title": data['title'] ?? "Assessment",
          "department": _getFullDepartmentName(departmentName),
          "exam_type": examType,
          "total_marks": totalMarks,
          "course_title": courseTitle,
          "credit_hours": creditHours,
          "paper_type": paperType,
          "marks": marksData,
          "custom_scenarios": (data['custom_scenarios'] as List?)?.map((sc) => {
            "text": sc['question'] ?? sc['text'] ?? "",
            "marks": sc['marks'] ?? 0.0,
            "type": sc['type'] ?? "Scenario",
            "target_clo": sc['target_clo'],
            "sub_parts": mapSubParts(sc),
          }).toList() ?? [],

          // BUG FIX: Explicitly passing 'marks' for all standard question types
          "mcqs": (data['mcqs'] as List?)?.map((m) => {
            "question": m['question'] ?? "",
            "options": m['options'] ?? [],
            "correctAnswer": m['correctAnswer'] ?? "",
            "target_clo": m['target_clo'],
            "marks": m['marks'] ?? marksData['mcq_points'] ?? 1.0,
          }).toList() ?? [],

          "shortQuestions": (data['shortQuestions'] as List?)?.map((sq) => {
            "question": sq['question'] ?? "",
            "idealAnswer": sq['idealAnswer'] ?? "",
            "target_clo": sq['target_clo'],
            "sub_parts": mapSubParts(sq),
            "marks": sq['marks'] ?? marksData['short_points'] ?? 3.0,
          }).toList() ?? [],

          "longQuestions": (data['longQuestions'] as List?)?.map((lq) => {
            "question": lq['question'] ?? "",
            "gradingRubric": lq['gradingRubric'] ?? "",
            "target_clo": lq['target_clo'],
            "sub_parts": mapSubParts(lq),
            "marks": lq['marks'] ?? marksData['long_points'] ?? 5.0,
          }).toList() ?? [],

          "fillInTheBlanks": (data['fillInTheBlanks'] as List?)?.map((fib) => {
            "question": fib['question'] ?? "",
            "answer": fib['answer'] ?? "",
            "target_clo": fib['target_clo'],
            "marks": fib['marks'] ?? marksData['fib_points'] ?? 1.0,
          }).toList() ?? [],

          "diagram_questions": data['diagram_questions'] ?? [],
        },
      };

      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 65));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final title = data['title'] ?? "Assessment";
        final output = await getTemporaryDirectory();
        final String filePath = "${output.path}/${title.replaceAll(' ', '_')}.docx";
        final file = File(filePath);

        await file.writeAsBytes(bytes);

        final params = ShareParams(
          files: [XFile(filePath)],
          text: 'Here is your generated Assessment Document!',
        );
        await SharePlus.instance.share(params);
        return true;
      } else if (response.statusCode == 422) {
        throw Exception("API Validation Error: ${response.body}");
      } else {
        throw Exception("API Error: ${response.statusCode}\nMessage: ${response.body}");
      }
    } on TimeoutException {
      throw Exception("Word Export Network Error: The Render server took too long to wake up.");
    } catch (e) {
      throw Exception("Word Export Error: $e");
    }
  }
}