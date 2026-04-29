import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:image_picker/image_picker.dart'; // <--- NEW IMPORT

class CloInputSection extends StatelessWidget {
  const CloInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider so the UI updates when we add/remove fields or load the camera
    final provider = context.watch<AssessmentProvider>();

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

          // --- UPDATED: Title, Optional Badge, and Camera Buttons ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Side: Title & Badge
              Row(
                children: [
                  Text(
                    "Learning Objectives",
                    style: TextStyle(
                      color: context.textPrimary,
                      fontFamily: "Lato",
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        "Optional",
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

              // Right Side: Magic Camera Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isExtractingCLOs)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.photo_library_rounded, size: 20, color: AppColors.primary),
                      tooltip: "Scan from Gallery",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => provider.scanCLOsFromImage(ImageSource.gallery),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.document_scanner_rounded, size: 20, color: AppColors.primary),
                      tooltip: "Scan with Camera",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => provider.scanCLOsFromImage(ImageSource.camera),
                    ),
                  ]
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          ...provider.cloControllers.asMap().entries.map((entry) {
            final int index = entry.key;
            final TextEditingController controller = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: UniversalTextField(
                      controller: controller,
                      labelText: "CLO ${index + 1}",
                      hintText: "e.g., Understand lexical analysis",
                    ),
                  ),
                  if (provider.cloControllers.length > 1) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => provider.removeClo(index),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: context.error,
                      ),
                      tooltip: "Remove CLO",
                    ),
                  ],
                ],
              ),
            );
          }),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => provider.addClo(),
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              label: const Text(
                "Add Objective",
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}