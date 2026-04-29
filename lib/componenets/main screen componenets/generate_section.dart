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

  @override
  Widget build(BuildContext context) {
    final assessmentProvider = context.watch<AssessmentProvider>();

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.border),
      ),
      // Added a bit more vertical padding at the top and bottom
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        // Added this so it scrolls gracefully if it gets too tall
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          // Changed to min so it wraps its content
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
                // Section Title
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

                // The Main Control Card
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
                      // --- The Dropdown Header ---
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
                            items:
                                [
                                  'Theory Based',
                                  'Theory + Code/Scenario',
                                  'Strictly Code/Scenario',
                                ].map((String value) {
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
                                }).toList(),
                            onChanged: assessmentProvider.updatePaperCategory,
                          ),
                        ),
                      ),

                      // --- The Smooth Expanding Settings Area ---
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child:
                            assessmentProvider.selectedPaperCategory ==
                                'Theory Based'
                            ? const SizedBox.shrink() // Hidden when Theory is selected
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
                                    // Premium Switch Tile instead of a Checkbox
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

                                    // Dynamic Custom Scenario List
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
                                                      // 👇 DYNAMIC LABEL 👇
                                                      labelText:
                                                          assessmentProvider
                                                              .letAIGenerateScenario
                                                          ? "AI Hint (e.g., 'C++ code with errors')"
                                                          : "Paste Exact Scenario / Code",
                                                      maxLines: 3,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 1,
                                                    child: UniversalTextField(
                                                      controller: assessmentProvider
                                                          .scenarioMarksControllers[index],
                                                      labelText: "Marks",
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
                                          // Sleek Outlined Button
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

            const SizedBox(height: 20), // Spacing before the "Variations" box

            const SizedBox(height: 16), // Spacing before the "Variations" box
            // --- Variations ---
            UniversalTextField(
              controller: assessmentProvider.variationsController,
              labelText: "Total variations (e.g. 3)",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16), // Added explicit spacing!
            // --- MCQs ---
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: context.widthPercent(0.55),
                  child: UniversalTextField(
                    controller: assessmentProvider.mcqCountController,
                    labelText: "Number of MCQs",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.mcqMarksController,
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16), // Added explicit spacing!
            // --- Fill in the Blanks ---
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: context.widthPercent(0.55),
                  child: UniversalTextField(
                    controller: assessmentProvider.fillBlankCountController,
                    // Wired!
                    labelText: "Fill in the Blanks",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.fillBlankMarksController,
                    // Wired!
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16), // Keeps our clean spacing
            // --- Short Questions ---
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: context.widthPercent(0.55),
                  child: UniversalTextField(
                    controller: assessmentProvider.shortCountController,
                    labelText: "Short Questions",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.shortMarksController,
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16), // Added explicit spacing!
            // --- Long Questions ---
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: context.widthPercent(0.55),
                  child: UniversalTextField(
                    controller: assessmentProvider.longCountController,
                    labelText: "Long Questions",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.longMarksController,
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24), // Extra space before the button!
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
                    // Changed from heightPercent to a fixed 50px so it doesn't squish
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
          ],
        ),
      ),
    );
  }
}
