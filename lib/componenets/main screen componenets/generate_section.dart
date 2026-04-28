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
    final assessmentProvider = context.read<AssessmentProvider>();

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

            const SizedBox(height: 20), // Added explicit spacing!
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
                    controller: assessmentProvider.fillBlankCountController, // Wired!
                    labelText: "Fill in the Blanks",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.fillBlankMarksController, // Wired!
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                )
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
