import 'dart:math' as math;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import '../../view_models/assessment_view_model.dart';
import '../../utils/responsive_ui.dart';

class UploadSection extends StatelessWidget {
  const UploadSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final files = vm.selectedFiles;
    final hasFiles = files.isNotEmpty;

    // Calculate total size of all currently selected files
    int totalBytes = 0;
    for (var f in files) {
      if (f.path != null) {
        totalBytes += File(f.path!).lengthSync();
      }
    }

    final double totalMB = totalBytes / (1024 * 1024);
    final double limitMB = (vm.maxFiles * vm.maxFileSizeInBytes) / (1024 * 1024); // e.g., 30 MB
    final double usagePercent = limitMB > 0 ? (totalMB / limitMB).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.heightPercent(0.01)),

          // --- HEADER ---
          Text(
            "Step 2: Upload Material",
            style: TextStyle(
              color: colorScheme.primary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: context.isMobile ? 22 : 26,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "Upload the syllabus, lecture slides, or reading materials. The AI will extract the context to generate your exam.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 14 : 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.04)),

          // --- MB CALCULATION PROGRESS BAR ---
          Container(
            padding: EdgeInsets.all(context.widthPercent(0.04)),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Upload Capacity",
                      style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      "${totalMB.toStringAsFixed(1)} MB / ${limitMB.toStringAsFixed(0)} MB",
                      style: TextStyle(color: colorScheme.primary, fontFamily: 'Lato', fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: context.heightPercent(0.015)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: usagePercent,
                    backgroundColor: colorScheme.outlineVariant.withAlpha(80),
                    color: usagePercent > 0.9 ? colorScheme.error : colorScheme.primary,
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.01)),
                Text(
                  "Max ${vm.maxFiles} files allowed",
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),

          // --- DROPZONE AREA ---
          if (vm.canAddMoreFiles)
            GestureDetector(
              onTap: () => vm.pickFile(context),
              behavior: HitTestBehavior.opaque,
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  radius: const Radius.circular(15),
                  color: colorScheme.primary,
                  strokeWidth: 2,
                  dashPattern: const [8.0, 8.0],
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: context.heightPercent(0.04)),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAngledIcon("assets/images/docx-file.png", -12, context),
                          Transform.translate(
                            offset: const Offset(0, -10),
                            child: _buildAngledIcon("assets/images/pdf.png", -3, context),
                          ),
                          _buildAngledIcon("assets/images/pptx.png", 15, context),
                        ],
                      ),
                      SizedBox(height: context.heightPercent(0.02)),
                      Text(
                        "Tap to browse files",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 16 : 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SizedBox(height: context.heightPercent(0.03)),

          // --- UPLOADED FILES LIST ---
          if (hasFiles) ...[
            Text(
              "Selected Files",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: context.heightPercent(0.015)),
            ...files.map((file) => _buildFileTile(file, vm, context, colorScheme)),
          ],

          SizedBox(height: context.heightPercent(0.04)), // Padding for scrolling
        ],
      ),
    );
  }

  Widget _buildAngledIcon(String assetPath, double angleDegrees, BuildContext context) {
    return Transform.rotate(
      angle: angleDegrees * (math.pi / 180),
      child: SizedBox(
        height: context.heightPercent(0.05),
        width: context.widthPercent(0.12),
        child: Image.asset(assetPath),
      ),
    );
  }

  Widget _buildFileTile(PlatformFile file, AssessmentViewModel vm, BuildContext context, ColorScheme colorScheme) {
    IconData fileIcon = Icons.insert_drive_file_rounded;
    Color iconColor = colorScheme.onSurfaceVariant;

    final String extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    final int fileSize = file.path != null ? File(file.path!).lengthSync() : 0;

    if (extension == 'pdf') {
      fileIcon = Icons.picture_as_pdf_rounded;
      iconColor = Colors.redAccent;
    } else if (extension == 'docx' || extension == 'doc') {
      fileIcon = Icons.description_rounded;
      iconColor = Colors.blueAccent;
    } else if (extension == 'pptx' || extension == 'ppt') {
      fileIcon = Icons.slideshow_rounded;
      iconColor = Colors.orangeAccent;
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.heightPercent(0.015)),
      padding: EdgeInsets.all(context.widthPercent(0.04)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(fileIcon, color: iconColor, size: 24),
          ),
          SizedBox(width: context.widthPercent(0.04)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error.withAlpha(200)),
            onPressed: () => vm.removeFile(file),
          ),
        ],
      ),
    );
  }
}