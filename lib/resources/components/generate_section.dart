import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'universal_text_field.dart';
import '../../view_models/assessment_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../views/assessment_views/assessment_preview_view.dart';

class GenerateSection extends StatelessWidget {
  const GenerateSection({super.key});

  Widget _buildConfigRow(
      BuildContext context, {
        required String title,
        required TextEditingController countCtrl,
        required TextEditingController marksCtrl,
        required ColorScheme colorScheme,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.02)),
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
                  fontSize: context.isMobile ? 15 : 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: context.widthPercent(0.02)),
          Expanded(
            flex: 2,
            child: UniversalTextField(
              controller: countCtrl,
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

  @override
  Widget build(BuildContext context) {
    final assessmentVM = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPercent(0.04),
        vertical: context.heightPercent(0.025),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Configuration",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: "Lato",
                    fontWeight: FontWeight.bold,
                    fontSize: context.isMobile ? 15 : 17,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.widthPercent(0.03),
                    vertical: context.heightPercent(0.005),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: colorScheme.primary.withAlpha(35),
                  ),
                  child: Center(
                    child: Text(
                      "Step 2",
                      style: TextStyle(
                        fontFamily: "Lato",
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.heightPercent(0.025)),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: context.widthPercent(0.01), bottom: context.heightPercent(0.01)),
                  child: Text(
                    "Exam Mode & Complexity",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: "Lato",
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.widthPercent(0.04),
                          vertical: context.heightPercent(0.008),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            borderRadius: BorderRadius.circular(10),
                            value: assessmentVM.selectedPaperCategory,
                            isExpanded: true,
                            dropdownColor: colorScheme.surface,
                            icon: Icon(Icons.tune_rounded, color: colorScheme.primary),
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontFamily: 'Lato',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            items: ['Theory Based', 'Theory + Code/Scenario']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      value == 'Theory Based'
                                          ? Icons.menu_book_rounded
                                          : value == 'Theory + Code/Scenario'
                                          ? Icons.account_tree_rounded
                                          : Icons.code_rounded,
                                      color: colorScheme.primary,
                                      size: 18,
                                    ),
                                    SizedBox(width: context.widthPercent(0.03)),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: assessmentVM.updatePaperCategory,
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: assessmentVM.selectedPaperCategory == 'Theory Based'
                            ? const SizedBox.shrink()
                            : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(15),
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.primary.withAlpha(30),
                                width: 1,
                              ),
                            ),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: Text(
                                  "Auto-Generate Scenarios",
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  "Let AI invent scenarios based on notes",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFamily: 'Lato',
                                    fontSize: 12,
                                  ),
                                ),
                                value: assessmentVM.letAIGenerateScenario,
                                onChanged: assessmentVM.toggleAIGenerateScenario,
                                activeColor: colorScheme.primary,
                                activeTrackColor: colorScheme.primary.withAlpha(50),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                  left: context.widthPercent(0.04),
                                  right: context.widthPercent(0.04),
                                  bottom: context.heightPercent(0.02),
                                ),
                                child: Column(
                                  children: [
                                    ...assessmentVM.scenarioTextControllers.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      bool isCodeMode = assessmentVM.scenarioTypes[index] == 'Code';

                                      return Padding(
                                        padding: EdgeInsets.only(top: context.heightPercent(0.015)),
                                        child: Container(
                                          padding: EdgeInsets.all(context.widthPercent(0.03)),
                                          decoration: BoxDecoration(
                                            color: theme.scaffoldBackgroundColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: colorScheme.outline.withAlpha(50)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  if (assessmentVM.letAIGenerateScenario)
                                                    SegmentedButton<String>(
                                                      segments: const [
                                                        ButtonSegment(value: 'Scenario', label: Text('Scenario')),
                                                        ButtonSegment(value: 'Code', label: Text('Code')),
                                                      ],
                                                      selected: {assessmentVM.scenarioTypes[index]},
                                                      onSelectionChanged: (Set<String> newSelection) {
                                                        assessmentVM.updateScenarioType(index, newSelection.first);
                                                      },
                                                      style: SegmentedButton.styleFrom(
                                                        visualDensity: VisualDensity.compact,
                                                        selectedForegroundColor: Colors.white,
                                                        selectedBackgroundColor: colorScheme.primary,
                                                      ),
                                                    )
                                                  else
                                                    Text(
                                                      "Exact Content ${index + 1}",
                                                      style: TextStyle(
                                                        color: colorScheme.onSurface,
                                                        fontFamily: 'Lato',
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  if (assessmentVM.scenarioTextControllers.length > 1)
                                                    IconButton(
                                                      icon: Icon(Icons.remove_circle, color: colorScheme.error.withAlpha(200)),
                                                      onPressed: () => assessmentVM.removeCustomScenario(index),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: context.heightPercent(0.015)),
                                              if (assessmentVM.letAIGenerateScenario && isCodeMode) ...[
                                                UniversalTextField(
                                                  controller: assessmentVM.scenarioLangControllers[index],
                                                  labelText: "Programming Language",
                                                  hintText: "e.g., Python, Dart, C++",
                                                ),
                                                SizedBox(height: context.heightPercent(0.015)),
                                              ],
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: UniversalTextField(
                                                      controller: assessmentVM.scenarioTextControllers[index],
                                                      labelText: assessmentVM.letAIGenerateScenario
                                                          ? (isCodeMode ? "Code Topic Hint" : "Scenario Hint")
                                                          : "Paste Exact Scenario / Code",
                                                      hintText: assessmentVM.letAIGenerateScenario
                                                          ? (isCodeMode ? "e.g., A function to reverse an array" : "e.g., A bank fraud case")
                                                          : "Paste the exact text or code snippet here...",
                                                      maxLines: assessmentVM.letAIGenerateScenario ? 2 : 4,
                                                    ),
                                                  ),
                                                  SizedBox(width: context.widthPercent(0.02)),
                                                  Expanded(
                                                    flex: 1,
                                                    child: UniversalTextField(
                                                      controller: assessmentVM.scenarioMarksControllers[index],
                                                      labelText: "Marks",
                                                      textAlign: TextAlign.center,
                                                      keyboardType: TextInputType.number,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    SizedBox(height: context.heightPercent(0.015)),
                                    OutlinedButton.icon(
                                      onPressed: assessmentVM.addCustomScenario,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text("Add Another"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                        side: BorderSide(color: colorScheme.primary.withAlpha(100)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: context.heightPercent(0.025)),
            _buildConfigRow(context, title: "Multiple Choice", countCtrl: assessmentVM.mcqCountController, marksCtrl: assessmentVM.mcqMarksController, colorScheme: colorScheme),
            _buildConfigRow(context, title: "Fill in Blanks", countCtrl: assessmentVM.fillBlankCountController, marksCtrl: assessmentVM.fillBlankMarksController, colorScheme: colorScheme),
            _buildConfigRow(context, title: "Short Questions", countCtrl: assessmentVM.shortCountController, marksCtrl: assessmentVM.shortMarksController, colorScheme: colorScheme),
            _buildConfigRow(context, title: "Long Questions", countCtrl: assessmentVM.longCountController, marksCtrl: assessmentVM.longMarksController, colorScheme: colorScheme),

            SizedBox(height: context.heightPercent(0.02)),

            Consumer<AssessmentViewModel>(
              builder: (context, vm, child) {
                final int currentMarks = vm.currentConfiguredMarks;
                final int targetMarks = vm.currentTargetMarks;
                final bool isCourseImported = vm.selectedCourseCode != null && targetMarks > 0;
                final bool hasFiles = vm.selectedFiles.isNotEmpty;
                final bool hasSelectedCLOs = !isCourseImported || vm.importedCLOs.any((clo) => clo['isSelected'] == true);

                final bool isExactMatch = isCourseImported ? (currentMarks == targetMarks) : (currentMarks > 0);
                final bool isOverLimit = isCourseImported ? currentMarks > targetMarks : false;
                final bool isUnderLimit = isCourseImported ? (currentMarks < targetMarks && currentMarks > 0) : false;

                final bool disableButton = vm.isLoading || !isExactMatch || !hasFiles || !hasSelectedCLOs;

                Color counterColor = colorScheme.onSurfaceVariant;
                String feedbackText = "";

                if (isCourseImported && isOverLimit) {
                  counterColor = Colors.redAccent;
                  feedbackText = "Marks Exceeded: $currentMarks / $targetMarks (Remove ${currentMarks - targetMarks})";
                } else if (isCourseImported && isUnderLimit) {
                  counterColor = Colors.orange;
                  feedbackText = "Marks Needed: $currentMarks / $targetMarks (Add ${targetMarks - currentMarks} more)";
                } else if (!isCourseImported && currentMarks == 0) {
                  counterColor = Colors.orange;
                  feedbackText = "Add question marks to continue.";
                } else if (!hasSelectedCLOs) {
                  counterColor = Colors.orange;
                  feedbackText = "Action Required: Select at least one CLO.";
                } else if (!hasFiles) {
                  counterColor = Colors.orange;
                  feedbackText = "Action Required: Upload curriculum notes.";
                } else {
                  counterColor = Colors.green;
                  feedbackText = isCourseImported ? "Perfect! Ready to generate." : "Ready to generate ($currentMarks marks).";
                }

                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.widthPercent(0.04),
                        vertical: context.heightPercent(0.01),
                      ),
                      margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
                      decoration: BoxDecoration(
                        color: counterColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: counterColor.withAlpha(80)),
                      ),
                      child: Text(
                        feedbackText,
                        style: TextStyle(
                          color: counterColor,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: disableButton
                          ? null
                          : () async {
                        FocusScope.of(context).unfocus();
                        await vm.triggerGeneration(context);
                        if (vm.generatedAssessment != null && context.mounted) {
                          await context.read<HistoryViewModel>().saveAssessment(vm.generatedAssessment!);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AssessmentPreviewView()),
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: context.heightPercent(0.065),
                        width: context.widthPercent(0.45),
                        decoration: BoxDecoration(
                          color: disableButton ? theme.scaffoldBackgroundColor.withAlpha(400) : colorScheme.primary,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: disableButton ? colorScheme.outline.withAlpha(50) : colorScheme.primary),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: vm.isLoading
                              ? [
                            SizedBox(
                              height: context.heightPercent(0.03),
                              width: context.heightPercent(0.03),
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                          ]
                              : [
                            Icon(Icons.auto_awesome, color: disableButton ? colorScheme.onSurfaceVariant : Colors.white, size: 20),
                            SizedBox(width: context.widthPercent(0.02)),
                            Text(
                              "Generate",
                              style: TextStyle(
                                color: disableButton ? colorScheme.onSurfaceVariant : Colors.white,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                fontSize: context.isMobile ? 16 : 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: context.heightPercent(0.1)),
          ],
        ),
      ),
    );
  }
}