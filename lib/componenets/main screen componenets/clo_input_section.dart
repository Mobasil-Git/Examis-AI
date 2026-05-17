import 'package:examis_ai/pages/course_catalog_page.dart'; // Adjust path if needed
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';

class CloInputSection extends StatelessWidget {
  const CloInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final isCourseSelected = provider.selectedCourseCode != null;

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "Course & Objectives",
                style: TextStyle(
                  color: context.textPrimary,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: AppColors.primary.withAlpha(35),
                ),
                child: const Center(
                  child: Text(
                    "Required",
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

          const SizedBox(height: 16),

          // --- STATE 1: No Course Selected ---
          if (!isCourseSelected)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Opens the Smart Search Catalog we built!
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourseCatalogPage()),
                  );
                },
                icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                label: const Text(
                  "Search Course Catalog",
                  style: TextStyle(color: AppColors.primary, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary.withAlpha(10),
                ),
              ),
            ),

          // --- STATE 2: Course Imported Successfully ---
          if (isCourseSelected)
            Container(
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withAlpha(50)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                title: Text(
                  provider.selectedCourseCode!,
                  style: TextStyle(color: context.textPrimary, fontFamily: 'Lato', fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  provider.selectedCourseTitle!,
                  style: TextStyle(color: context.textSecondary, fontFamily: 'Lato', fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.error),
                  onPressed: () => provider.clearImportedCourse(),
                  tooltip: "Remove Course",
                ),
              ),
            ),
        ],
      ),
    );
  }
}