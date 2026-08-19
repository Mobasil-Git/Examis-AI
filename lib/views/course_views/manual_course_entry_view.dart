import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../resources/components/universal_text_field.dart';
import '../../view_models/assessment_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../utils/responsive_ui.dart';

class ManualCourseEntryView extends StatefulWidget {
  const ManualCourseEntryView({super.key});

  @override
  State<ManualCourseEntryView> createState() => _ManualCourseEntryViewState();
}

class _ManualCourseEntryViewState extends State<ManualCourseEntryView> {
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _creditHoursController = TextEditingController();
  bool _isPublishing = false;
  String? _selectedDepartmentId;

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
    final vm = context.read<AssessmentViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please select a Department or Shared Pool."), backgroundColor: colorScheme.error));
      return;
    }
    if (vm.selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please go back and select a Session Batch first!"), backgroundColor: colorScheme.error));
      return;
    }

    if (_codeController.text.isEmpty || _titleController.text.isEmpty || _creditHoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Course Code, Title, and Credit Hours are required."), backgroundColor: colorScheme.error));
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final courseResponse = await supabase.from('master_courses').insert({
        'batch_id': vm.selectedBatch!['id'],
        'department_id': _selectedDepartmentId,
        'course_code': _codeController.text.trim().toUpperCase(),
        'title': _titleController.text.trim(),
        'credit_hours': _creditHoursController.text.trim(),
      }).select('id').single();

      final newCourseId = courseResponse['id'];

      final List<Map<String, dynamic>> closToInsert = _clos.map((clo) => {
        'course_id': newCourseId,
        'description': clo['description'],
        'domain': clo['domain'],
        'bt_level': clo['bt_level'],
        'plo_id': clo['plo_id'],
      }).toList();

      await supabase.from('master_clos').insert(closToInsert);
      await supabase.from('user_courses').insert({
        'user_id': userId,
        'course_id': newCourseId,
      });

      if (!context.mounted) return;

      context.read<AssessmentViewModel>().setImportedCourse(
        _codeController.text.trim().toUpperCase(),
        _titleController.text.trim(),
        closToInsert,
        _creditHoursController.text.trim(),
        vm.selectedDepartmentName ?? "BSCS",
      );

      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course Published & Imported!"), backgroundColor: Colors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Error: Course code might already exist or invalid data."), backgroundColor: colorScheme.error));
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final assessmentVM = context.watch<AssessmentViewModel>();
    final themeVM = context.watch<ThemeViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Dynamic AppBar coloring
        backgroundColor: themeVM.isDarkMode ? colorScheme.surface : colorScheme.primary,
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
              padding: EdgeInsets.all(context.widthPercent(0.06)),
              children: [
                Text("Assign to Department", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 18 : 20)),
                SizedBox(height: context.heightPercent(0.01)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04), vertical: context.heightPercent(0.005)),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withAlpha(50)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDepartmentId,
                      isExpanded: true,
                      dropdownColor: colorScheme.surface,
                      hint: Text("Select Department (or Shared Pool)", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      items: assessmentVM.departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept['id'] as String,
                          child: Text(
                            dept['name'],
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: dept['name'].toString().contains('General') ? FontWeight.bold : FontWeight.normal,
                              color: dept['name'].toString().contains('General') ? colorScheme.primary : colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDepartmentId = val),
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(0.03)),
                Text("Course Details", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 18 : 20)),
                SizedBox(height: context.heightPercent(0.02)),
                Row(
                  children: [
                    Expanded(child: UniversalTextField(controller: _codeController, labelText: "Course Code", hintText: "e.g., CS-304")),
                    SizedBox(width: context.widthPercent(0.04)),
                    Expanded(child: UniversalTextField(controller: _creditHoursController, labelText: "Credit Hours", hintText: "e.g., 4(3-1)")),
                  ],
                ),
                SizedBox(height: context.heightPercent(0.02)),
                UniversalTextField(controller: _titleController, labelText: "Course Title", hintText: "e.g., Object Oriented Prog."),
                SizedBox(height: context.heightPercent(0.04)),
                Text("Learning Objectives (CLOs)", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 18 : 20)),
                SizedBox(height: context.heightPercent(0.02)),
                ..._clos.asMap().entries.map((entry) {
                  int index = entry.key;
                  return _buildCloCard(index, colorScheme);
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addClo,
                    icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
                    label: Text("Add Another CLO", style: TextStyle(color: colorScheme.primary, fontFamily: 'Lato', fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(context.widthPercent(0.06)),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: context.heightPercent(0.065),
              child: ElevatedButton(
                onPressed: _isPublishing ? null : _publishToCatalog,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isPublishing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Publish to Global Catalog", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: context.isMobile ? 16 : 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloCard(int index, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.widthPercent(0.04)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Objective ${index + 1}", style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold, color: colorScheme.primary)),
                if (_clos.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                    onPressed: () => _removeClo(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            SizedBox(height: context.heightPercent(0.015)),
            TextFormField(
              initialValue: _clos[index]['description'],
              onChanged: (val) => _clos[index]['description'] = val,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "e.g., Understand principles of OOP...",
                hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: context.heightPercent(0.015)),
            Row(
              children: [
                Expanded(child: _buildDropdown(context, "Domain", ['C', 'P', 'A'], _clos[index]['domain'], (val) => setState(() => _clos[index]['domain'] = val), colorScheme)),
                SizedBox(width: context.widthPercent(0.02)),
                Expanded(child: _buildDropdown(context, "BT Level", [1, 2, 3, 4, 5, 6], _clos[index]['bt_level'], (val) => setState(() => _clos[index]['bt_level'] = val), colorScheme)),
                SizedBox(width: context.widthPercent(0.02)),
                Expanded(child: _buildDropdown(context, "PLO", List.generate(12, (i) => i + 1), _clos[index]['plo_id'], (val) => setState(() => _clos[index]['plo_id'] = val), colorScheme)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String label, List<dynamic> items, dynamic currentValue, Function(dynamic) onChanged, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontFamily: 'Lato', color: colorScheme.onSurfaceVariant)),
        SizedBox(height: context.heightPercent(0.005)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.03)),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<dynamic>(
              borderRadius: BorderRadius.circular(15),
              dropdownColor: colorScheme.surface,
              value: currentValue,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.onSurfaceVariant),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item.toString(), style: TextStyle(fontSize: 13, color: colorScheme.onSurface)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}