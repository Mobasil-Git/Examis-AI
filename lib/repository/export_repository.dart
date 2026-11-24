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

  double _parseMarks(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  // STRICT CLO HELPER: Ensures target_clo is never null
  dynamic _parseClo(dynamic val, {dynamic fallbackClo}) {
    if (val != null) {
      if (val is List && val.isNotEmpty)
        return val.map((e) => e.toString()).toList();
      if (val is String && val.trim().isNotEmpty) return val.trim();
    }
    return fallbackClo ?? "CLO-1";
  }

  // --- NEW STRICT SANITIZERS ---
  // Forcefully flattens any string to remove newlines, carriage returns, and tabs
  // that get mutated by database deserialization and break the Word Template XML loop.
  String _sanitizeText(dynamic text) {
    if (text == null) return "";
    return text
        .toString()
        .replaceAll(
          RegExp(r'[\n\r\t]'),
          ' ',
        ) // Replace breaks/tabs with a space
        .replaceAll(RegExp(r'\s+'), ' ') // Collapse multiple spaces into one
        .trim();
  }

  List<String> _sanitizeOptions(dynamic options) {
    if (options == null || options is! List) return [];
    return options.map((e) => _sanitizeText(e)).toList();
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

      final Map<String, dynamic> rawMarks = data['marks'] ?? {};
      final Map<String, dynamic> marksData = {
        "mcq_points": _parseMarks(rawMarks['mcq_points'] ?? 1.0),
        "short_points": _parseMarks(rawMarks['short_points'] ?? 3.0),
        "long_points": _parseMarks(rawMarks['long_points'] ?? 10.0),
        "fib_points": _parseMarks(rawMarks['fib_points'] ?? 1.0),
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

      List<Map<String, dynamic>> mapSubParts(dynamic item, dynamic parentClo) {
        if (item['sub_parts'] != null && item['sub_parts'] is List) {
          return (item['sub_parts'] as List)
              .map(
                (sp) => {
                  "label": _sanitizeText(sp['label'] ?? "a"),
                  "question": _sanitizeText(sp['question']),
                  "marks": _parseMarks(sp['marks']),
                  "target_clo": _parseClo(
                    sp['target_clo'],
                    fallbackClo: parentClo,
                  ),
                },
              )
              .toList();
        }
        return [];
      }

      // Payload is now 100% sanitized before transmission
      final payload = {
        "template_url": templateUrl,
        "show_clo_tags": showCloTags,
        "exam_data": {
          "title": _sanitizeText(data['title'] ?? "Assessment"),
          "department": _getFullDepartmentName(departmentName),
          "exam_type": _sanitizeText(examType),
          "total_marks": totalMarks,
          "course_title": _sanitizeText(courseTitle),
          "credit_hours": _sanitizeText(creditHours),
          "paper_type": paperType,
          "marks": marksData,

          "custom_scenarios":
              (data['custom_scenarios'] as List?)?.map((sc) {
                final clo = _parseClo(sc['target_clo']);
                return {
                  "text": _sanitizeText(sc['question'] ?? sc['text']),
                  "marks": _parseMarks(sc['marks']),
                  "type": _sanitizeText(sc['type'] ?? "Scenario"),
                  "target_clo": clo,
                  "sub_parts": mapSubParts(sc, clo),
                };
              }).toList() ??
              [],

          "mcqs":
              (data['mcqs'] as List?)?.map((m) {
                final clo = _parseClo(m['target_clo']);
                return {
                  "question": _sanitizeText(m['question']),
                  "options": _sanitizeOptions(m['options']),
                  // Forcefully sanitized array
                  "correctAnswer": _sanitizeText(m['correctAnswer']),
                  "target_clo": clo,
                  "marks": _parseMarks(m['marks'] ?? marksData['mcq_points']),
                  "image_url": m['image_url'],
                };
              }).toList() ??
              [],

          "shortQuestions":
              (data['shortQuestions'] as List?)?.map((sq) {
                final clo = _parseClo(sq['target_clo']);
                return {
                  "question": _sanitizeText(sq['question']),
                  "idealAnswer": _sanitizeText(sq['idealAnswer']),
                  "target_clo": clo,
                  "sub_parts": mapSubParts(sq, clo),
                  "marks": _parseMarks(
                    sq['marks'] ?? marksData['short_points'],
                  ),
                  "image_url": sq['image_url'],
                };
              }).toList() ??
              [],

          "longQuestions":
              (data['longQuestions'] as List?)?.map((lq) {
                final clo = _parseClo(lq['target_clo']);
                return {
                  "question": _sanitizeText(lq['question']),
                  "gradingRubric": _sanitizeText(lq['gradingRubric']),
                  "target_clo": clo,
                  "sub_parts": mapSubParts(lq, clo),
                  "marks": _parseMarks(lq['marks'] ?? marksData['long_points']),
                  "image_url": lq['image_url'],
                };
              }).toList() ??
              [],

          "fillInTheBlanks":
              (data['fillInTheBlanks'] as List?)?.map((fib) {
                final clo = _parseClo(fib['target_clo']);
                return {
                  "question": _sanitizeText(fib['question']),
                  "answer": _sanitizeText(fib['answer']),
                  "target_clo": clo,
                  "marks": _parseMarks(fib['marks'] ?? marksData['fib_points']),
                  "image_url": fib['image_url'],
                };
              }).toList() ??
              [],

          "diagram_questions":
              (data['diagram_questions'] as List?)?.map((dq) {
                final clo = _parseClo(dq['target_clo']);
                return {
                  "question": _sanitizeText(dq['question']),
                  "marks": _parseMarks(dq['marks']),
                  "target_clo": clo,
                  "image_url": dq['image_url'],
                };
              }).toList() ??
              [],
        },
      };

      final response = await http
          .post(
            apiUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 65));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final title = data['title'] ?? "Assessment";
        final output = await getTemporaryDirectory();

        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String filePath =
            "${output.path}/${title.replaceAll(' ', '_')}_$timestamp.docx";
        final file = File(filePath);

        await file.writeAsBytes(bytes);

        final params = ShareParams(
          files: [XFile(filePath)],
          text: 'Here is your generated Assessment Document!',
        );
        await SharePlus.instance.share(params);
        return true;
      } else if (response.statusCode == 422) {
        throw Exception(
          "Document Validation Failed: Ensure marks add up correctly and all fields are filled.",
        );
      } else {
        throw Exception(
          "Server Error (${response.statusCode}): Could not generate document.",
        );
      }
    } on TimeoutException {
      throw Exception(
        "Word Export Network Error: The Vercel server took too long to respond.",
      );
    } catch (e) {
      throw Exception("Word Export Error: $e");
    }
  }
}
