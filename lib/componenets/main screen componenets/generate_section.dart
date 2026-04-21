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
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [

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
                  height: context.heightPercent(0.035),
                  width: context.widthPercent(0.15),
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

            UniversalTextField(
              controller: assessmentProvider.variationsController, // Wired!
              labelText: "Total variations (e.g. 3)",
              keyboardType: TextInputType.number,
            ),

            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: context.widthPercent(0.58),
                  child: UniversalTextField(
                    controller: assessmentProvider.mcqCountController, // Wired!
                    labelText: "Number of MCQs",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.mcqMarksController, // Wired!
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                )
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: context.widthPercent(0.58),
                  child: UniversalTextField(
                    controller: assessmentProvider.shortCountController, // Wired!
                    labelText: "Short Questions",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.shortMarksController, // Wired!
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                )
              ],
            ),

            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: context.widthPercent(0.58),
                  child: UniversalTextField(
                    controller: assessmentProvider.longCountController, // Wired!
                    labelText: "Long Questions",
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: context.widthPercent(0.25),
                  child: UniversalTextField(
                    controller: assessmentProvider.longMarksController, // Wired!
                    labelText: "Marks each",
                    keyboardType: TextInputType.number,
                  ),
                )
              ],
            ),

            Consumer<AssessmentProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onTap: provider.isLoading
                      ? null
                      : () async {

                    FocusScope.of(context).unfocus();

                    final prefs = await SharedPreferences.getInstance();
                    final String difficulty = prefs.getString('selectedDifficulty') ?? "Medium";
                    await provider.triggerGeneration(context, difficulty: difficulty);

                    if (provider.generatedAssessment != null && context.mounted) {

                      await context.read<HistoryProvider>().saveAssessment(provider.generatedAssessment!);

                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AssessmentPreviewPage()),
                      );
                    }
                  },
                  child: Container(
                    height: context.heightPercent(0.06),
                    width: context.widthPercent(0.4),
                    decoration: BoxDecoration(
                      color: provider.isLoading
                          ? (context.isDarkMode ? context.surface.withAlpha(150) : context.primary.withAlpha(150))
                          : (context.isDarkMode ? context.background : context.primary),
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
                        )
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