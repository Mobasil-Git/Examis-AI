import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'animated_exam_type_selector.dart';
import '../../views/course_views/course_catalog_view.dart';
import '../../view_models/assessment_view_model.dart';
import '../../utils/responsive_ui.dart';

class CloInputSection extends StatelessWidget {
  const CloInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(context.widthPercent(0.05)), // Responsive padding
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: colorScheme.primary),
                  SizedBox(width: context.widthPercent(0.03)),
                  Text(
                    "Course & Objectives",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 16 : 18,
                    ),
                  ),
                ],
              ),
              if (vm.selectedCourseCode != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CourseCatalogView()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Change",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.heightPercent(0.02)),
          if (vm.selectedCourseCode != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.widthPercent(0.03)),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withAlpha(50)),
              ),
              child: Text(
                "${vm.selectedCourseCode}: ${vm.selectedCourseTitle}",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: context.isMobile ? 15 : 17,
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(0.03)),
            AnimatedExamTypeSelector(
              hasPractical: vm.hasPractical,
              onTypeSelected: (type) {
                context.read<AssessmentViewModel>().setExamType(type);
              },
            ),
            SizedBox(height: context.heightPercent(0.02)),

            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.05), vertical: context.heightPercent(0.01)),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.primary.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.track_changes_rounded, color: colorScheme.primary, size: 18),
                    SizedBox(width: context.widthPercent(0.02)),
                    Text(
                      "Required Marks: ${vm.currentTargetMarks}",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (vm.selectedExamType == 'Practical') ...[
              SizedBox(height: context.heightPercent(0.03)),
              const PracticalBreakdownDashboard(),
            ] else ...[
              SizedBox(height: context.heightPercent(0.03)),
              Text(
                "Select Target CLOs",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: context.isMobile ? 14 : 16,
                ),
              ),
              SizedBox(height: context.heightPercent(0.015)),
              Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: vm.importedCLOs.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> clo = entry.value;

                    return CheckboxListTile(
                      activeColor: colorScheme.primary,
                      contentPadding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.02), vertical: context.heightPercent(0.005)),
                      title: Text(
                        "CLO ${index + 1} (BT: ${clo['bt_level']})",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 13 : 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        clo['description'] ?? "",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: context.isMobile ? 12 : 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: clo['isSelected'] ?? true,
                      onChanged: (bool? value) {
                        context.read<AssessmentViewModel>().toggleCloSelection(index, value);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: context.heightPercent(0.06), // Responsive button height
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourseCatalogView()),
                  );
                },
                icon: Icon(Icons.search, color: colorScheme.primary),
                label: Text(
                  "Search Course Catalog",
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: context.isMobile ? 15 : 17,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary.withAlpha(100), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PracticalBreakdownDashboard extends StatefulWidget {
  const PracticalBreakdownDashboard({super.key});

  @override
  State<PracticalBreakdownDashboard> createState() => _PracticalBreakdownDashboardState();
}

class _PracticalBreakdownDashboardState extends State<PracticalBreakdownDashboard> {
  late TextEditingController _vivaController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AssessmentViewModel>();
    _vivaController = TextEditingController(text: vm.vivaWeightage.toString());
  }

  @override
  void dispose() {
    _vivaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(context.widthPercent(0.04)),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Marks Distribution",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              fontSize: context.isMobile ? 13 : 15,
            ),
          ),
          SizedBox(height: context.heightPercent(0.02)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Viva / Quizzes",
                      style: TextStyle(
                        fontSize: context.isMobile ? 12 : 14,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.01)),
                    TextFormField(
                      controller: _vivaController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontFamily: 'Lato', color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outline.withAlpha(50)),
                        ),
                      ),
                      onChanged: (value) {
                        context.read<AssessmentViewModel>().updateVivaWeightage(value);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.widthPercent(0.04)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lab Tasks / Code",
                      style: TextStyle(
                        fontSize: context.isMobile ? 12 : 14,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.01)),
                    Container(
                      height: 48, // Keeping internal textfield parity
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04)),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withAlpha(30)),
                      ),
                      child: Text(
                        "${vm.labTaskWeightage}",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 16 : 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}