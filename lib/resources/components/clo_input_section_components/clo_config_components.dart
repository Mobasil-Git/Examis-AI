import 'package:examisai/resources/components/animated_exam_type_selector.dart';
import 'package:examisai/resources/components/universal_text_field.dart';
import 'package:examisai/utils/responsive_ui.dart';
import 'package:examisai/view_models/assessment_view_model.dart';
import 'package:examisai/views/course_views/course_catalog_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class CourseAndGlobalConfigStep extends StatelessWidget {
  const CourseAndGlobalConfigStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPercent(0.06),
        vertical: context.heightPercent(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Course Selection",
            style: TextStyle(
              color: colorScheme.primary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: context.isMobile ? 22 : 26,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "Select a course from the catalog to fetch its objectives.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 14 : 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),

          Container(
            padding: EdgeInsets.all(context.widthPercent(0.05)),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: context.widthPercent(0.03)),
                        Text(
                          "Course Settings",
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CourseCatalogView(),
                          ),
                        ),
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
                    padding: EdgeInsets.all(context.widthPercent(0.04)),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${vm.selectedCourseCode}: ${vm.selectedCourseTitle}",
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.bold,
                            fontSize: context.isMobile ? 15 : 17,
                          ),
                        ),
                        SizedBox(height: context.heightPercent(0.01)),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: colorScheme.onPrimaryContainer.withAlpha(150)),
                            SizedBox(width: 4),
                            Text(
                              "Credit Hours: ${vm.courseCreditHours}",
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer.withAlpha(200),
                                fontFamily: 'Lato',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.03)),
                  AnimatedExamTypeSelector(
                    hasPractical: vm.hasPractical,
                    onTypeSelected: (type) =>
                        context.read<AssessmentViewModel>().setExamType(type),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: context.heightPercent(0.06),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CourseCatalogView(),
                        ),
                      ),
                      icon: const Icon(Icons.search),
                      label: Text(
                        "Search Course Catalog",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 15 : 17,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (vm.selectedCourseCode != null &&
              (vm.randomMCQs ||
                  vm.randomFillBlanks ||
                  vm.randomShortQs ||
                  vm.randomLongQs))
            const RandomizedDistributionSection(),
        ],
      ),
    );
  }
}

class FinalMatrixAndValidationStep extends StatelessWidget {
  const FinalMatrixAndValidationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool needsMatrix =
        (vm.wantsMCQs && !vm.randomMCQs) ||
            (vm.wantsFillBlanks && !vm.randomFillBlanks) ||
            (vm.wantsShortQs && !vm.randomShortQs) ||
            (vm.wantsLongQs && !vm.randomLongQs);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPercent(0.06),
        vertical: context.heightPercent(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Final Matrix & Review",
            style: TextStyle(
              color: colorScheme.primary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: context.isMobile ? 22 : 26,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "Finalize the standard question distribution and validate your overall marks.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 14 : 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),

          if (vm.selectedCourseCode != null) ...[
            if (vm.selectedExamType == 'Practical')
              const PracticalBreakdownDashboard()
            else if (needsMatrix) ...[
              Text(
                "CLO Allocation Matrix",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: context.isMobile ? 14 : 16,
                ),
              ),
              SizedBox(height: context.heightPercent(0.015)),
              ...vm.importedCLOs.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> clo = entry.value;
                bool isSelected = clo['isSelected'] ?? true;
                return Container(
                  margin: EdgeInsets.only(bottom: context.heightPercent(0.015)),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary.withAlpha(50)
                          : colorScheme.outline.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: CheckboxListTile(
                          activeColor: colorScheme.primary,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: context.widthPercent(0.03),
                            vertical: context.heightPercent(0.005),
                          ),
                          title: Text(
                            "CLO ${index + 1} (BT: ${clo['bt_level']})",
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: context.isMobile ? 14 : 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            clo['description'] ?? "",
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: context.isMobile ? 12 : 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? value) => context
                              .read<AssessmentViewModel>()
                              .toggleCloSelection(index, value),
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: EdgeInsets.only(
                            left: context.widthPercent(0.04),
                            right: context.widthPercent(0.04),
                            bottom: context.heightPercent(0.02),
                          ),
                          child: Column(
                            children: [
                              if (vm.wantsMCQs && !vm.randomMCQs)
                                WizardMatrixRow(
                                  title: "MCQs",
                                  qtyCtrl: clo['mcq_qty'],
                                  marksCtrl: clo['mcq_marks'],
                                ),
                              if (vm.wantsFillBlanks && !vm.randomFillBlanks)
                                WizardMatrixRow(
                                  title: "Fill Blanks",
                                  qtyCtrl: clo['fib_qty'],
                                  marksCtrl: clo['fib_marks'],
                                ),
                              if (vm.wantsShortQs && !vm.randomShortQs)
                                WizardMatrixRow(
                                  title: "Short Qs",
                                  qtyCtrl: clo['short_qty'],
                                  marksCtrl: clo['short_marks'],
                                ),
                              if (vm.wantsLongQs && !vm.randomLongQs)
                                WizardMatrixRow(
                                  title: "Long Qs",
                                  qtyCtrl: clo['long_qty'],
                                  marksCtrl: clo['long_marks'],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

class RandomizedDistributionSection extends StatelessWidget {
  const RandomizedDistributionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(top: context.heightPercent(0.02)),
      padding: EdgeInsets.all(context.widthPercent(0.05)),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shuffle_rounded, color: colorScheme.secondary),
              SizedBox(width: context.widthPercent(0.03)),
              Text(
                "Randomized Distribution",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: context.isMobile ? 16 : 18,
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "AI will randomly assign these across all active CLOs.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: 13,
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),
          if (vm.randomMCQs)
            WizardMatrixRow(
              title: "MCQs",
              qtyCtrl: vm.globalMcqQtyCtrl,
              marksCtrl: vm.globalMcqMarksCtrl,
            ),
          if (vm.randomFillBlanks)
            WizardMatrixRow(
              title: "Fill Blanks",
              qtyCtrl: vm.globalFibQtyCtrl,
              marksCtrl: vm.globalFibMarksCtrl,
            ),
          if (vm.randomShortQs)
            WizardMatrixRow(
              title: "Short Qs",
              qtyCtrl: vm.globalShortQtyCtrl,
              marksCtrl: vm.globalShortMarksCtrl,
            ),
          if (vm.randomLongQs)
            WizardMatrixRow(
              title: "Long Qs",
              qtyCtrl: vm.globalLongQtyCtrl,
              marksCtrl: vm.globalLongMarksCtrl,
            ),
        ],
      ),
    );
  }
}

class WizardMatrixRow extends StatelessWidget {
  final String title;
  final TextEditingController qtyCtrl;
  final TextEditingController marksCtrl;

  const WizardMatrixRow({
    super.key,
    required this.title,
    required this.qtyCtrl,
    required this.marksCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(0.012)),
              child: Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: 'Lato',
                  fontSize: context.isMobile ? 13 : 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: context.widthPercent(0.02)),
          Expanded(
            flex: 2,
            child: UniversalTextField(
              controller: qtyCtrl,
              labelText: "Qty",
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: context.widthPercent(0.02)),
          Expanded(
            flex: 2,
            child: UniversalTextField(
              controller: marksCtrl,
              labelText: "Marks",
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }
}

class PracticalBreakdownDashboard extends StatefulWidget {
  const PracticalBreakdownDashboard({super.key});

  @override
  State<PracticalBreakdownDashboard> createState() =>
      _PracticalBreakdownDashboardState();
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
                      style: TextStyle(
                        fontFamily: 'Lato',
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.widthPercent(0.04),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withAlpha(50),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withAlpha(50),
                          ),
                        ),
                      ),
                      onChanged: (value) => context
                          .read<AssessmentViewModel>()
                          .updateVivaWeightage(value),
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
                      height: 48,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.widthPercent(0.04),
                      ),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withAlpha(30),
                        ),
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
