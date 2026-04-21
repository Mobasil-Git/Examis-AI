import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:docx_creator/docx_creator.dart';

class ExportService {
  Future<bool> exportToPdf(Map<String, dynamic> data) async {
    try {
      final pdf = pw.Document();
      final prefs = await SharedPreferences.getInstance();
      final institutionName =
          prefs.getString('institutionName') ?? "Examis AI Assessment";
      final title = data['title'] ?? "Assessment";
      final mcqs = data['mcqs'] ?? [];
      final shortQs = data['shortQuestions'] ?? [];
      final longQs = data['longQuestions'] ?? [];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  institutionName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.SizedBox(height: 16),
              if (mcqs.isNotEmpty) ...[
                pw.Text(
                  "Multiple Choice Questions",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...mcqs.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final q = entry.value;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "$index. ${q['question']}",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 6),
                      ...(q['options'] as List<dynamic>).map(
                        (opt) => pw.Padding(
                          padding: const pw.EdgeInsets.only(
                            left: 16,
                            bottom: 4,
                          ),
                          child: pw.Text(
                            opt.toString(),
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                    ],
                  );
                }),
              ],
              if (shortQs.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  "Short Answer Questions",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...shortQs.asMap().entries.map((entry) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "${entry.key + 1}. ${entry.value['question']}",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 40),
                    ],
                  );
                }),
              ],
              if (longQs.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  "Long Essay Questions",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...longQs.asMap().entries.map((entry) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "${entry.key + 1}. ${entry.value['question']}",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 100),
                    ],
                  );
                }),
              ],
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/${title.replaceAll(' ', '_')}.pdf");
      await file.writeAsBytes(await pdf.save());

      final params = ShareParams(
        files: [XFile(file.path)],
        text: 'Here is the generated assessment!',
      );
      await SharePlus.instance.share(params);
      return true;
    } catch (e) {
      print("PDF Export Error: $e");
      return false;
    }
  }

  Future<bool> exportToWord(Map<String, dynamic> data) async {
    try {
      final title = data['title'] ?? "Assessment";
      var document = docx();
      document.h1(title.toUpperCase());
      document.p("--------------------------------------------------");
      if (data['mcqs'] != null && data['mcqs'].isNotEmpty) {
        document.h2("MULTIPLE CHOICE QUESTIONS");
        int i = 1;
        for (var q in data['mcqs']) {
          document.add(
            DocxParagraph(
              children: [
                DocxText("$i. ", fontWeight: DocxFontWeight.bold),
                DocxText("${q['question']}"),
              ],
            ),
          );

          List<dynamic> options = q['options'] ?? [];

          for (int j = 0; j < options.length; j += 2) {
            String leftLetter = String.fromCharCode(97 + j);

            String rawLeft = options[j].toString();
            String cleanLeft = rawLeft
                .replaceAll(RegExp(r'^[a-zA-Z][\.\)]\s*'), '')
                .trim();

            List<DocxText> rowContent = [
              DocxText("    $leftLetter) ", fontWeight: DocxFontWeight.bold),
              DocxText(cleanLeft),
            ];
            if (j + 1 < options.length) {
              String rightLetter = String.fromCharCode(97 + j + 1);

              String rawRight = options[j + 1].toString();
              String cleanRight = rawRight
                  .replaceAll(RegExp(r'^[a-zA-Z][\.\)]\s*'), '')
                  .trim();

              rowContent.add(DocxText("\t\t\t\t\t"));
              rowContent.add(
                DocxText("$rightLetter) ", fontWeight: DocxFontWeight.bold),
              );
              rowContent.add(DocxText(cleanRight));
            }

            document.add(DocxParagraph(children: rowContent));
          }

          document.p("");
          i++;
        }
      }

      if (data['shortQuestions'] != null && data['shortQuestions'].isNotEmpty) {
        document.h2("SHORT ANSWER QUESTIONS");
        int i = 1;
        for (var q in data['shortQuestions']) {
          document.add(
            DocxParagraph(
              children: [
                DocxText("$i. ", fontWeight: DocxFontWeight.bold),
                DocxText("${q['question']}"),
              ],
            ),
          );
          document.p("\n\n");
          i++;
        }
      }

      if (data['longQuestions'] != null && data['longQuestions'].isNotEmpty) {
        document.h2("LONG ESSAY QUESTIONS");
        int i = 1;
        for (var q in data['longQuestions']) {
          document.add(
            DocxParagraph(
              children: [
                DocxText("$i. ", fontWeight: DocxFontWeight.bold),
                DocxText("${q['question']}"),
              ],
            ),
          );
          document.p("\n\n\n\n\n"); // Spacing for essay
          i++;
        }
      }

      final builtDoc = document.build();
      final output = await getTemporaryDirectory();
      final String filePath =
          "${output.path}/${title.replaceAll(' ', '_')}.docx";

      await DocxExporter().exportToFile(builtDoc, filePath);

      final params = ShareParams(
        files: [XFile(filePath)],
        text: 'Here is the generated Word Document!',
      );
      await SharePlus.instance.share(params);
      return true;
    } catch (e) {
      print("Word Export Error: $e");
      return false;
    }
  }
}
