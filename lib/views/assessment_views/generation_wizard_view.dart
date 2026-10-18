import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../view_models/assessment_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../utils/utils.dart';

import 'package:examisai/resources/components/exam_ingredients_section.dart';
import 'package:examisai/resources/components/upload_section.dart';
import 'package:examisai/resources/components/clo_input_section_components/clo_config_components.dart';
import 'package:examisai/resources/components/clo_input_section_components/clo_advanced_components.dart';
import '../assessment_views/assessment_preview_view.dart';

class GenerationWizardView extends StatefulWidget {
  const GenerationWizardView({super.key});

  @override
  State<GenerationWizardView> createState() => _GenerationWizardViewState();
}

class _GenerationWizardViewState extends State<GenerationWizardView> {
  int _currentStep = 0;

  List<Widget> _buildWizardPages(AssessmentViewModel vm) {
    List<Widget> pages = [
      const ExamIngredientsSection(key: ValueKey('step_ingredients')),
      const UploadSection(key: ValueKey('step_upload')),
      const CourseAndGlobalConfigStep(key: ValueKey('step_course_config')),
    ];

    if (vm.wantsCustomQuestions) {
      pages.add(const CustomQuestionsStep(key: ValueKey('step_custom_questions')));
    }
    if (vm.wantsScenariosOrCode) {
      pages.add(const ScenariosStep(key: ValueKey('step_scenarios')));
    }
    if (vm.wantsDiagrams) {
      pages.add(const DiagramsStep(key: ValueKey('step_diagrams')));
    }

    pages.add(const FinalMatrixAndValidationStep(key: ValueKey('step_final_matrix')));
    pages.add(const AssessmentPreviewView(key: ValueKey('step_preview')));

    return pages;
  }

  void _goToPage(int pageIndex) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentStep = pageIndex;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToPage(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<AssessmentViewModel>();

    final List<Widget> pages = _buildWizardPages(vm);
    final int totalSteps = pages.length;

    if (_currentStep >= totalSteps) {
      _currentStep = totalSteps - 1;
    }

    final bool isGenerateStep = _currentStep == (totalSteps - 2);
    final bool isPreviewStep = _currentStep == (totalSteps - 1);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isPreviewStep
          ? null
          : AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Generate Exam",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (!isPreviewStep)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.widthPercent(0.06),
                      vertical: context.heightPercent(0.02),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        // The progress bar now perfectly fills up to 100% on the generate step
                        value: (_currentStep + 1) / (totalSteps - 1),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: colorScheme.primary,
                        minHeight: 8,
                      ),
                    ),
                  ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Container(
                      key: ValueKey<int>(_currentStep),
                      child: pages[_currentStep],
                    ),
                  ),
                ),

                if (!isPreviewStep && _currentStep >= 2 && vm.selectedCourseCode != null)
                  _buildGlobalMarksTracker(context, vm, colorScheme),

                if (!isPreviewStep)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(context.widthPercent(0.06)),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(50),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: vm.isLoading ? null : _prevStep,
                          child: Text(
                            _currentStep == 0 ? "Cancel" : "Back",
                            style: TextStyle(
                              color: vm.isLoading
                                  ? colorScheme.onSurface.withAlpha(100)
                                  : colorScheme.onSurfaceVariant,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: context.widthPercent(0.3),
                            maxWidth: context.widthPercent(0.45),
                          ),
                          child: ElevatedButton(
                            onPressed: vm.isLoading
                                ? null
                                : () async {
                              Widget currentPage = pages[_currentStep];

                              if (currentPage is ExamIngredientsSection) {
                                if (!vm.hasSelectedIngredients) {
                                  Utils.showSnackBar(context, "Please select at least one ingredient.", colorScheme.error);
                                  return;
                                }
                              } else if (currentPage is UploadSection) {
                                if (vm.selectedFiles.isEmpty) {
                                  Utils.showSnackBar(context, "Please upload curriculum materials.", colorScheme.error);
                                  return;
                                }
                              } else if (currentPage is CourseAndGlobalConfigStep) {
                                if (!vm.validateCourseConfig()) {
                                  Utils.showSnackBar(context, "Please select a course and fill in required fields.", colorScheme.error);
                                  return;
                                }
                              } else if (currentPage is CustomQuestionsStep) {
                                if (!vm.validateCustomQuestions()) {
                                  Utils.showSnackBar(context, "Please complete all custom question fields and select target CLOs.", colorScheme.error);
                                  return;
                                }
                              } else if (currentPage is ScenariosStep) {
                                if (!vm.validateScenarios()) {
                                  Utils.showSnackBar(context, "Please complete all scenario fields and select target CLOs.", colorScheme.error);
                                  return;
                                }
                              } else if (currentPage is DiagramsStep) {
                                if (!vm.validateDiagrams()) {
                                  Utils.showSnackBar(context, "Please provide an image, question, marks, and target CLO for all diagrams.", colorScheme.error);
                                  return;
                                }
                              } else if (currentPage is FinalMatrixAndValidationStep) {
                                String? validationError = vm.validateFinalMatrix();
                                if (validationError != null) {
                                  Utils.showSnackBar(context, validationError, colorScheme.error);
                                  return;
                                }

                                FocusManager.instance.primaryFocus?.unfocus();

                                await vm.triggerGeneration(context);

                                if (vm.generatedAssessment != null && context.mounted) {
                                  _goToPage(totalSteps - 1);
                                }
                                return;
                              }

                              _goToPage(_currentStep + 1);
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: colorScheme.primary,
                              disabledBackgroundColor: colorScheme.primary.withAlpha(100),
                              padding: EdgeInsets.symmetric(vertical: context.heightPercent(0.015)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              isGenerateStep ? "Generate" : "Next",
                              style: const TextStyle(color: Colors.white, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (vm.isLoading && isGenerateStep)
              const Positioned.fill(
                child: _AIGenerationOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalMarksTracker(BuildContext context, AssessmentViewModel vm, ColorScheme colorScheme) {
    final double currentMarks = vm.currentConfiguredMarks;
    final double targetMarks = vm.currentTargetMarks;

    String fmt(double m) => m.truncateToDouble() == m ? m.toInt().toString() : m.toStringAsFixed(1);

    final bool isExactMatch = currentMarks == targetMarks;
    final bool isOverLimit = currentMarks > targetMarks;

    Color statusColor = colorScheme.onSurfaceVariant;
    String statusText = "Action Required: Enter questions.";

    if (currentMarks == 0) {
      statusColor = Colors.orange;
      statusText = "Target: ${fmt(targetMarks)} Marks";
    } else if (isOverLimit) {
      statusColor = Colors.redAccent;
      statusText = "Exceeded: ${fmt(currentMarks)} / ${fmt(targetMarks)} (-${fmt(currentMarks - targetMarks)})";
    } else if (currentMarks < targetMarks) {
      statusColor = Colors.orange;
      statusText = "Needed: ${fmt(currentMarks)} / ${fmt(targetMarks)} (+${fmt(targetMarks - currentMarks)})";
    } else {
      statusColor = Colors.green;
      statusText = "Perfect Match: ${fmt(currentMarks)} / ${fmt(targetMarks)}";
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04), vertical: context.heightPercent(0.012)),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(20),
        border: Border(top: BorderSide(color: statusColor.withAlpha(50))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isExactMatch ? Icons.check_circle_rounded : Icons.track_changes_rounded, color: statusColor, size: 20),
          SizedBox(width: context.widthPercent(0.02)),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 14 : 16),
          )
        ],
      ),
    );
  }
}

// --- NEW COMPONENT: AI Generation Loading Overlay ---

class _AIGenerationOverlay extends StatefulWidget {
  const _AIGenerationOverlay();

  @override
  State<_AIGenerationOverlay> createState() => _AIGenerationOverlayState();
}

class _AIGenerationOverlayState extends State<_AIGenerationOverlay> {
  String _message = "AI is analyzing your curriculum... 🧠";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Updates the message dynamically after 6 seconds to reassure the user
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _message = "Generating questions & structuring the blueprint...\nGrab a sip of tea! ☕";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withAlpha(120), // Dims the background and blocks all taps
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.widthPercent(0.1)),
        padding: EdgeInsets.all(context.widthPercent(0.06)),
        decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/lottie_animations/AI.json', // Reusing your cool AI lottie file!
              height: context.heightPercent(0.12),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            CircularProgressIndicator(color: colorScheme.primary),
            SizedBox(height: context.heightPercent(0.03)),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: context.isMobile ? 15 : 17,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}