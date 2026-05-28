import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualCourseEntryPage extends StatefulWidget {
  const ManualCourseEntryPage({super.key});

  @override
  State<ManualCourseEntryPage> createState() => _ManualCourseEntryPageState();
}

class _ManualCourseEntryPageState extends State<ManualCourseEntryPage> {
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _creditHoursController = TextEditingController();
  bool _isPublishing = false;
  String? _selectedDepartmentId;

  // We start them off with one empty CLO
  final List<Map<String, dynamic>> _clos = [
    {'description': '', 'domain': 'C', 'bt_level': 2, 'plo_id': 1},
  ];

  void _addClo() {
    setState(() {
      _clos.add({'description': '', 'domain': 'C', 'bt_level': 2, 'plo_id': 1});
    });
  }

  void _removeClo(int index) {
    if (_clos.length > 1) {
      setState(() {
        _clos.removeAt(index);
      });
    }
  }

  Future<void> _publishToCatalog() async {
    final provider = context.read<AssessmentProvider>();
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a Department or Shared Pool."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (provider.selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please go back and select a Session Batch first!"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_codeController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _creditHoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Course Code, Title, and Credit Hours are required."),
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

      // 2. Prepare Master CLOs
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

      // 3. Insert CLOs
      await supabase.from('master_clos').insert(closToInsert);

      // 4. Link to Teacher's Library
      await supabase.from('user_courses').insert({
        'user_id': userId,
        'course_id': newCourseId,
      });

      if (!context.mounted) return;

      // 5. Update Provider so it shows on the Dashboard immediately!
      context.read<AssessmentProvider>().setImportedCourse(
        _codeController.text.trim().toUpperCase(),
        _titleController.text.trim(),
        closToInsert,
        _creditHoursController.text.trim(),
        provider.selectedDepartmentName ?? "BSCS",
      );

      // Close this page AND the catalog page, dropping them back on the dashboard
      Navigator.pop(context); // Pops Manual Entry
      Navigator.pop(context); // Pops Catalog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Course Published & Imported!"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error: Course code might already exist or invalid data.",
          ),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isPublishing = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _creditHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: theme.isDarkMode ? context.surface : AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Manual Course Entry",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  "Assign to Department",
                  style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(50)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDepartmentId,
                      isExpanded: true,
                      dropdownColor: context.surface,
                      hint: const Text("Select Department (or Shared Pool)"),
                      items: context.watch<AssessmentProvider>().departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept['id'] as String,
                          child: Text(
                            dept['name'],
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: dept['name'].toString().contains('General')
                                  ? FontWeight.bold : FontWeight.normal,
                              // Highlight the General pool slightly so they notice it
                              color: dept['name'].toString().contains('General')
                                  ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDepartmentId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Course Details",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: UniversalTextField(
                        controller: _codeController,
                        labelText: "Course Code",
                        hintText: "e.g., CS-304",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: UniversalTextField(
                        controller: _creditHoursController,
                        labelText: "Credit Hours",
                        hintText: "e.g., 4(3-1)",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                UniversalTextField(
                  controller: _titleController,
                  labelText: "Course Title",
                  hintText: "e.g., Object Oriented Prog.",
                ),

                const SizedBox(height: 32),
                const Text(
                  "Learning Objectives (CLOs)",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),

                ..._clos.asMap().entries.map((entry) {
                  int index = entry.key;
                  return _buildCloCard(index);
                }),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addClo,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      "Add Another CLO",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // The Bumper & Publish Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }

  // --- The Individual CLO Builder ---
  Widget _buildCloCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: context.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Objective ${index + 1}",
                  style: const TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (_clos.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: () => _removeClo(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Description input
            TextFormField(
              initialValue: _clos[index]['description'],
              onChanged: (val) => _clos[index]['description'] = val,
              decoration: InputDecoration(
                hintText: "e.g., Understand principles of OOP...",
                hintStyle: const TextStyle(fontSize: 14),
                filled: true,
                fillColor: context.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    "Domain",
                    ['C', 'P', 'A'],
                    _clos[index]['domain'],
                        (val) => setState(() => _clos[index]['domain'] = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    "BT Level",
                    [1, 2, 3, 4, 5, 6],
                    _clos[index]['bt_level'],
                        (val) => setState(() => _clos[index]['bt_level'] = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    "PLO",
                    List.generate(12, (i) => i + 1),
                    _clos[index]['plo_id'],
                        (val) => setState(() => _clos[index]['plo_id'] = val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label,
      List<dynamic> items,
      dynamic currentValue,
      Function(dynamic) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Lato',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              borderRadius: BorderRadius.circular(15),
              dropdownColor: context.surface,
              value: currentValue,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, size: 16),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}