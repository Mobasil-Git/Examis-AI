import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../pages/assessment_preview_page.dart';

class GenerateSection extends StatelessWidget {
  const GenerateSection({super.key});

  Widget _buildConfigRow(
    BuildContext context, {
    required String title,
    required TextEditingController countCtrl,
    required TextEditingController marksCtrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontFamily: 'Lato',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: UniversalTextField(
              controller: countCtrl,
              labelText: "Qty",
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
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
    final assessmentProvider = context.watch<AssessmentProvider>();

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Header Row ---
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Configuration",
                  style: TextStyle(
                    color: context.textPrimary,
                    fontFamily: "Lato",
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: AppColors.primary.withAlpha(35),
                  ),
                  child: const Center(
                    child: Text(
                      "Step 2",
                      style: TextStyle(
                        fontFamily: "Lato",
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Paper Category Dropdown ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    "Exam Mode & Complexity",
                    style: TextStyle(
                      color: AppColors.primary,
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
                    color: context.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: assessmentProvider.selectedPaperCategory,
                            isExpanded: true,
                            dropdownColor: context.surface,
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.primary,
                            ),
                            style: TextStyle(
                              color: context.textPrimary,
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
                                              : value ==
                                                    'Theory + Code/Scenario'
                                              ? Icons.account_tree_rounded
                                              : Icons.code_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(value),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                            onChanged: assessmentProvider.updatePaperCategory,
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child:
                            assessmentProvider.selectedPaperCategory ==
                                'Theory Based'
                            ? const SizedBox.shrink()
                            : Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(15),
                                  border: Border(
                                    top: BorderSide(
                                      color: AppColors.primary.withAlpha(30),
                                      width: 1,
                                    ),
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SwitchListTile(
                                      title: Text(
                                        "Auto-Generate Scenarios",
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontFamily: 'Lato',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Let AI invent scenarios based on notes",
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontFamily: 'Lato',
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: assessmentProvider
                                          .letAIGenerateScenario,
                                      onChanged: assessmentProvider
                                          .toggleAIGenerateScenario,
                                      activeColor: AppColors.primary,
                                      activeTrackColor: AppColors.primary
                                          .withAlpha(50),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        bottom: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          ...assessmentProvider.scenarioTextControllers.asMap().entries.map((
                                            entry,
                                          ) {
                                            int index = entry.key;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12.0,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: UniversalTextField(
                                                      controller: assessmentProvider
                                                          .scenarioTextControllers[index],
                                                      labelText:
                                                          assessmentProvider
                                                              .letAIGenerateScenario
                                                          ? "AI Hint"
                                                          : "Paste Exact Scenario",
                                                      hintText:
                                                          "e.g., C++ errors",
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 1,
                                                    child: UniversalTextField(
                                                      controller: assessmentProvider
                                                          .scenarioMarksControllers[index],
                                                      labelText: "Marks",
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                    ),
                                                  ),
                                                  if (assessmentProvider
                                                          .scenarioTextControllers
                                                          .length >
                                                      1)
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.remove_circle,
                                                        color: context.error
                                                            .withAlpha(200),
                                                      ),
                                                      onPressed: () =>
                                                          assessmentProvider
                                                              .removeCustomScenario(
                                                                index,
                                                              ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            onPressed: assessmentProvider
                                                .addCustomScenario,
                                            icon: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                            label: const Text("Add Another"),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primary,
                                              side: BorderSide(
                                                color: AppColors.primary
                                                    .withAlpha(100),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
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

            const SizedBox(height: 24),
            // Removed Variations and its spacing, jumping straight to inputs!

            // 🚀 THE CLEAN ROWS
            _buildConfigRow(
              context,
              title: "Multiple Choice",
              countCtrl: assessmentProvider.mcqCountController,
              marksCtrl: assessmentProvider.mcqMarksController,
            ),

            _buildConfigRow(
              context,
              title: "Fill in Blanks",
              countCtrl: assessmentProvider.fillBlankCountController,
              marksCtrl: assessmentProvider.fillBlankMarksController,
            ),

            _buildConfigRow(
              context,
              title: "Short Questions",
              countCtrl: assessmentProvider.shortCountController,
              marksCtrl: assessmentProvider.shortMarksController,
            ),

            _buildConfigRow(
              context,
              title: "Long Questions",
              countCtrl: assessmentProvider.longCountController,
              marksCtrl: assessmentProvider.longMarksController,
            ),

            const SizedBox(height: 24),

            // --- Generate Button ---
            Consumer<AssessmentProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onTap: provider.isLoading
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          final prefs = await SharedPreferences.getInstance();
                          final String difficulty =
                              prefs.getString('selectedDifficulty') ?? "Medium";
                          await provider.triggerGeneration(
                            context,
                            difficulty: difficulty,
                          );

                          if (provider.generatedAssessment != null &&
                              context.mounted) {
                            await context
                                .read<HistoryProvider>()
                                .saveAssessment(provider.generatedAssessment!);
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssessmentPreviewPage(),
                              ),
                            );
                          }
                        },
                  child: Container(
                    height: 50,
                    width: context.widthPercent(0.4),
                    decoration: BoxDecoration(
                      color: provider.isLoading
                          ? (context.isDarkMode
                                ? context.surface.withAlpha(150)
                                : context.primary.withAlpha(150))
                          : (context.isDarkMode
                                ? context.background
                                : context.primary),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: provider.isLoading
                          ? const [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ]
                          : const [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Generate",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
