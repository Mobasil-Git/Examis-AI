import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';

class DiagramInputSection extends StatelessWidget {
  const DiagramInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_photo_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Diagrams & Visuals",
                style: TextStyle(
                  color: context.textPrimary,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

          const SizedBox(height: 16),

          if (provider.diagramTextControllers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(30), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.image_search, color: AppColors.primary.withAlpha(150), size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "No diagrams added yet.",
                    style: TextStyle(color: context.textSecondary, fontFamily: 'Lato', fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => provider.addDiagramQuestion(),
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text(
                      "Add Diagram Question",
                      style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...provider.diagramTextControllers.asMap().entries.map((entry) {
              final int index = entry.key;
              final File? selectedImage = provider.diagramImages[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Inputs Row ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align to top so label drops correctly
                        children: [
                          Expanded(
                            flex: 3,
                            child: UniversalTextField(
                              controller: provider.diagramTextControllers[index],
                              labelText: "Question prompt",
                              hintText: "e.g., Label the diagram",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: UniversalTextField(
                              controller: provider.diagramMarksControllers[index],
                              labelText: "Marks",
                              hintText: "5",
                              textAlign: TextAlign.center, // 🚀 CENTERED
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0), // Pushes icon down to align with input field
                            child: IconButton(
                              onPressed: () => provider.removeDiagramQuestion(index),
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                              tooltip: "Remove Diagram",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- Image Picker Row ---
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => provider.pickDiagramImage(index, ImageSource.gallery),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: context.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.border, width: 1.5),
                              ),
                              child: selectedImage != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(selectedImage, fit: BoxFit.cover),
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: context.textSecondary, size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Upload",
                                    style: TextStyle(fontSize: 10, fontFamily: 'Lato', color: context.textSecondary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Attach an image for the AI to process and include in the final Word document.",
                                  style: TextStyle(color: context.textSecondary, fontFamily: 'Lato', fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildActionChip(
                                      context,
                                      icon: Icons.photo_library,
                                      label: "Gallery",
                                      onTap: () => provider.pickDiagramImage(index, ImageSource.gallery),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionChip(
                                      context,
                                      icon: Icons.camera_alt,
                                      label: "Camera",
                                      onTap: () => provider.pickDiagramImage(index, ImageSource.camera),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 4),

            TextButton.icon(
              onPressed: () => provider.addDiagramQuestion(),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
              label: const Text(
                "Add Another Diagram",
                style: TextStyle(color: AppColors.primary, fontFamily: 'Lato', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppColors.primary, fontFamily: 'Lato', fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}