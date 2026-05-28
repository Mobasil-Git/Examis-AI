import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewSyllabusSheet extends StatefulWidget {
  final Map<String, dynamic> aiExtractedData;

  const ReviewSyllabusSheet({super.key, required this.aiExtractedData});

  @override
  State<ReviewSyllabusSheet> createState() => _ReviewSyllabusSheetState();
}

class _ReviewSyllabusSheetState extends State<ReviewSyllabusSheet> {
  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _creditHoursController;
  late List<Map<String, dynamic>> _clos;

  String? _selectedDepartmentId;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.aiExtractedData['course_code'] ?? "",
    );
    _titleController = TextEditingController(
      text: widget.aiExtractedData['course_title'] ?? "",
    );
    _creditHoursController = TextEditingController(
      text: widget.aiExtractedData['credit_hours'] ?? "3(3-0)",
    );

    _clos = List<Map<String, dynamic>>.from(
      widget.aiExtractedData['clos'] ?? [],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _creditHoursController.dispose();
    super.dispose();
  }

  Future<void> _publishToCatalog() async {
    final provider = context.read<AssessmentProvider>();

    if (provider.selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select a Session Batch on the catalog page first!",
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please assign this course to a Department (or Shared Pool).",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final courseResponse = await supabase
          .from('master_courses')
          .insert({
        'batch_id': provider.selectedBatch!['id'],
        'department_id': _selectedDepartmentId,
        'course_code': _codeController.text.trim().toUpperCase(),
        'title': _titleController.text.trim(),
        'credit_hours': _creditHoursController.text.trim(),
      })
          .select('id')
          .single();

      final newCourseId = courseResponse['id'];

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

      await supabase.from('user_courses').insert({
        'user_id': userId,
        'course_id': newCourseId,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Publish Error: $e");
      if (mounted) {
        if (e.toString().contains('unique_course_per_batch_dept')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "This course already exists in this Department for this Session.",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error publishing: $e",
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }

        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 THE FIX: Wrap the entire sheet in a transparent Scaffold!
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true, // This gives you the buttery smooth keyboard animation!
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          // 🚀 THE FIX: Changed 'height' to 'constraints' so the Scaffold can smoothly shrink it!
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _clos.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
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
                              "Verify the details and assign a department before publishing.",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontFamily: 'Lato',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: UniversalTextField(
                                    controller: _codeController,
                                    labelText: "Code",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: UniversalTextField(
                                    controller: _creditHoursController,
                                    labelText: "Credit Hrs",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            UniversalTextField(
                              controller: _titleController,
                              labelText: "Title",
                            ),
                            const SizedBox(height: 16),
                            _buildDepartmentDropdown(context),
                            const SizedBox(height: 24),
                            const Text(
                              "Extracted Objectives (CLOs)",
                              style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }

                      final clo = _clos[index - 1];
                      return Card(
                        color: context.surface,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withAlpha(50),
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
                      elevation: 0,
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
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Assign to Department",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(50),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartmentId,
              isExpanded: true,
              dropdownColor: context.surface,
              hint: const Text("Select Department (or Shared Pool)"),
              items: context.watch<AssessmentProvider>().departments.map((
                  dept,
                  ) {
                final isGeneral = dept['name'].toString().contains('General');
                return DropdownMenuItem<String>(
                  value: dept['id'] as String,
                  child: Text(
                    dept['name'],
                    style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: isGeneral
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isGeneral
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedDepartmentId = val),
            ),
          ),
        ),
      ],
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