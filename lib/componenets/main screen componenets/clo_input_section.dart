import 'package:examis_ai/app_animations/dashboard_animation/animated_exam_type_selector.dart';
import 'package:examis_ai/pages/course_catalog_page.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CloInputSection extends StatelessWidget {
  const CloInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    "Course & Objectives",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (provider.selectedCourseCode != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CourseCatalogPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Change",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.selectedCourseCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(50)),
              ),
              child: Text(
                "${provider.selectedCourseCode}: ${provider.selectedCourseTitle}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedExamTypeSelector(
              hasPractical: provider.hasPractical,
              onTypeSelected: (type) {
                context.read<AssessmentProvider>().setExamType(type);
              },
            ),
            const SizedBox(height: 16),

            // The Glowing Target Marks Pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.track_changes_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Required Marks: ${provider.currentTargetMarks}",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🚀 THE SPLITTER: Show Practical Breakdown OR CLO List
            if (provider.selectedExamType == 'Practical') ...[
              const SizedBox(height: 24),
              const PracticalBreakdownDashboard(),
            ] else ...[
              const SizedBox(height: 24),
              Text(
                "Select Target CLOs",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: provider.importedCLOs.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> clo = entry.value;

                    return CheckboxListTile(
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      title: Text(
                        "CLO ${index + 1} (BT: ${clo['bt_level']})",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        clo['description'] ?? "",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: clo['isSelected'] ?? true,
                      onChanged: (bool? value) {
                        context.read<AssessmentProvider>().toggleCloSelection(
                          index,
                          value,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CourseCatalogPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.search, color: AppColors.primary),
                label: const Text(
                  "Search Course Catalog",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primary.withAlpha(100),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 🚀 NEW COMPONENT: Practical Breakdown Mini-Dashboard
class PracticalBreakdownDashboard extends StatefulWidget {
  const PracticalBreakdownDashboard({super.key});

  @override
  State<PracticalBreakdownDashboard> createState() =>
      _PracticalBreakdownDashboardState();
}

class _PracticalBreakdownDashboardState
    extends State<PracticalBreakdownDashboard> {
  late TextEditingController _vivaController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AssessmentProvider>();
    _vivaController = TextEditingController(
      text: provider.vivaWeightage.toString(),
    );
  }

  @override
  void dispose() {
    _vivaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Marks Distribution",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Viva / Quizzes",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _vivaController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontFamily: 'Lato'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withAlpha(50),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withAlpha(50),
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        context.read<AssessmentProvider>().updateVivaWeightage(
                          value,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lab Tasks / Code",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      // Matches standard TextFormField height
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        "${provider.labTaskWeightage}",
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
