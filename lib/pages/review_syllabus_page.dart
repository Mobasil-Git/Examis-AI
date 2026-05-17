import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewSyllabusSheet extends StatefulWidget {
  // This is the parsed JSON map that Gemini returns!
  final Map<String, dynamic> aiExtractedData;

  const ReviewSyllabusSheet({super.key, required this.aiExtractedData});

  @override
  State<ReviewSyllabusSheet> createState() => _ReviewSyllabusSheetState();
}

class _ReviewSyllabusSheetState extends State<ReviewSyllabusSheet> {
  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late List<Map<String, dynamic>> _clos;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the text boxes with Gemini's hard work
    _codeController = TextEditingController(
      text: widget.aiExtractedData['course_code'] ?? "",
    );
    _titleController = TextEditingController(
      text: widget.aiExtractedData['course_title'] ?? "",
    );

    // Safely cast the CLOs array
    _clos = List<Map<String, dynamic>>.from(
      widget.aiExtractedData['clos'] ?? [],
    );
  }

  Future<void> _publishToCatalog() async {
    setState(() => _isPublishing = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Insert into Master Courses
      final courseResponse = await supabase
          .from('master_courses')
          .insert({
            'course_code': _codeController.text.trim(),
            'title': _titleController.text.trim(),
          })
          .select('id')
          .single();

      final newCourseId = courseResponse['id'];

      // 2. Prepare and Insert Master CLOs
      final List<Map<String, dynamic>> closToInsert = _clos
          .map(
            (clo) => {
              'course_id': newCourseId,
              'description': clo['description'],
              'domain': clo['domain'],
              'bt_level': clo['bt_level'],
              'plo_id': clo['plo_id'],
            },
          )
          .toList();

      await supabase.from('master_clos').insert(closToInsert);

      // 3. Automatically add it to the teacher's personal library!
      await supabase.from('user_courses').insert({
        'user_id': userId,
        'course_id': newCourseId,
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true for success!
      }
    } catch (e) {
      print("Publish Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error publishing: $e"),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Review AI Extraction",
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Verify the details before publishing to the global catalog.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: UniversalTextField(
                    controller: _codeController,
                    labelText: "Code",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: UniversalTextField(
                    controller: _titleController,
                    labelText: "Title",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "Extracted Objectives (CLOs)",
              style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: _clos.length,
                itemBuilder: (context, index) {
                  final clo = _clos[index];
                  return Card(
                    color: context.surface,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(50),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clo['description'] ?? "",
                            style: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildTag("Domain: ${clo['domain']}"),
                              const SizedBox(width: 8),
                              _buildTag("BT: ${clo['bt_level']}"),
                              const SizedBox(width: 8),
                              _buildTag("PLO: ${clo['plo_id']}"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _publishToCatalog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Publish to Global Catalog",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
