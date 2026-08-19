import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'universal_text_field.dart';
import '../../view_models/assessment_view_model.dart';
import '../../utils/responsive_ui.dart';

class DiagramInputSection extends StatelessWidget {
  const DiagramInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      padding: EdgeInsets.all(context.widthPercent(0.04)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.insert_photo_outlined, color: colorScheme.primary, size: 20),
              SizedBox(width: context.widthPercent(0.02)),
              Text(
                "Diagrams & Visuals",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: "Lato",
                  fontWeight: FontWeight.bold,
                  fontSize: context.isMobile ? 16 : 18,
                ),
              ),
              SizedBox(width: context.widthPercent(0.02)),
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
                    "Optional",
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
          SizedBox(height: context.heightPercent(0.02)),

          if (vm.diagramTextControllers.isEmpty)
            InkWell(
              onTap: () => vm.addDiagramQuestion(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: context.heightPercent(0.03)),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withAlpha(30),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add, color: colorScheme.primary.withAlpha(150), size: 32),
                    SizedBox(height: context.heightPercent(0.015)),
                    Text(
                      "No diagrams added yet.",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Lato',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...vm.diagramTextControllers.asMap().entries.map((entry) {
              final int index = entry.key;
              final File? selectedImage = vm.diagramImages[index];

              return Padding(
                padding: EdgeInsets.only(bottom: context.heightPercent(0.02)),
                child: Container(
                  padding: EdgeInsets.all(context.widthPercent(0.04)),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: UniversalTextField(
                              controller: vm.diagramTextControllers[index],
                              labelText: "Question prompt",
                              hintText: "e.g., Label the diagram",
                            ),
                          ),
                          SizedBox(width: context.widthPercent(0.03)),
                          Expanded(
                            flex: 1,
                            child: UniversalTextField(
                              controller: vm.diagramMarksControllers[index],
                              labelText: "Marks",
                              hintText: "5",
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: context.widthPercent(0.01)),
                          Padding(
                            padding: EdgeInsets.only(top: context.heightPercent(0.03)),
                            child: IconButton(
                              onPressed: () => vm.removeDiagramQuestion(index),
                              icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
                              tooltip: "Remove Diagram",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.heightPercent(0.02)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => vm.pickDiagramImage(index, ImageSource.gallery),
                            child: Container(
                              width: context.widthPercent(0.2),
                              height: context.widthPercent(0.2),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outline.withAlpha(50), width: 1.5),
                              ),
                              child: selectedImage != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(selectedImage, fit: BoxFit.cover),
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: colorScheme.onSurfaceVariant, size: 24),
                                  SizedBox(height: context.heightPercent(0.005)),
                                  Text(
                                    "Upload",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Lato',
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: context.widthPercent(0.04)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Attach an image for the AI to process and include in the final Word document.",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFamily: 'Lato',
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: context.heightPercent(0.01)),
                                Row(
                                  children: [
                                    _buildActionChip(
                                      context,
                                      colorScheme,
                                      icon: Icons.photo_library,
                                      label: "Gallery",
                                      onTap: () => vm.pickDiagramImage(index, ImageSource.gallery),
                                    ),
                                    SizedBox(width: context.widthPercent(0.02)),
                                    _buildActionChip(
                                      context,
                                      colorScheme,
                                      icon: Icons.camera_alt,
                                      label: "Camera",
                                      onTap: () => vm.pickDiagramImage(index, ImageSource.camera),
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
            SizedBox(height: context.heightPercent(0.005)),
            TextButton.icon(
              onPressed: () => vm.addDiagramQuestion(),
              icon: Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 20),
              label: Text(
                "Add Another Diagram",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, ColorScheme colorScheme, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.03), vertical: context.heightPercent(0.01)),
        decoration: BoxDecoration(
          color: colorScheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.primary.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.primary),
            SizedBox(width: context.widthPercent(0.015)),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.primary,
                fontFamily: 'Lato',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}