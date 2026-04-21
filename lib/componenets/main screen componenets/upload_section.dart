import 'dart:math' as math;
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:provider/provider.dart';

class UploadSection extends StatelessWidget {
  const UploadSection({super.key});

  @override
  Widget build(BuildContext context) {
    final iconHeight = context.heightPercent(0.06);
    final iconWidth = context.widthPercent(0.15);

    final assessmentProvider = context.watch<AssessmentProvider>();
    final files = assessmentProvider.selectedFiles;
    final hasFiles = files.isNotEmpty;

    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(15),
        color: AppColors.primary,
        strokeWidth: 2,
        dashPattern: const [8.0, 8.0],
      ),
      child: Container(
        height: context.heightPercent(0.24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "Upload Source",
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
                        "Step 1",
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

              const SizedBox(height: 12),

              Expanded(
                child: hasFiles
                    ? _buildFileList(context, assessmentProvider)
                    : _buildEmptyState(context, iconHeight, iconWidth, assessmentProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double iconHeight, double iconWidth, AssessmentProvider provider) {
    return GestureDetector(
      onTap: () => provider.pickFile(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: -12 * (math.pi / 180),
                child: SizedBox(height: iconHeight, width: iconWidth, child: Image.asset("assets/images/docx-file.png")),
              ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Transform.rotate(
                  angle: -3 * (math.pi / 180),
                  child: SizedBox(height: iconHeight, width: iconWidth, child: Image.asset("assets/images/pdf.png")),
                ),
              ),
              Transform.rotate(
                angle: 15 * (math.pi / 180),
                child: SizedBox(height: iconHeight, width: iconWidth, child: Image.asset("assets/images/pptx.png")),
              ),
            ],
          ),
          const SizedBox(height: 12),
           Text(
            "Tap here to browse files",
            style: TextStyle(
              color: context.textPrimary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
           Text(
            "Max 3 files (10MB limit per file)",
            style: TextStyle(
              color: context.textSecondary,
              fontFamily: 'Lato',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, AssessmentProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...provider.selectedFiles.map((file) => _buildFileTile(file, provider,context)).toList(),

          if (provider.canAddMoreFiles)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => provider.pickFile(context),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                label: const Text(
                  "Add Another File",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppColors.primary.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileTile(PlatformFile file, AssessmentProvider provider, BuildContext context) {
    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = context.textSecondary;

    if (file.extension == 'pdf') {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.redAccent;
    } else if (file.extension == 'docx' || file.extension == 'doc') {
      fileIcon = Icons.description;
      iconColor = Colors.blueAccent;
    } else if (file.extension == 'pptx' || file.extension == 'ppt') {
      fileIcon = Icons.slideshow;
      iconColor = Colors.orangeAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Icon(fileIcon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB",
                  style:  TextStyle(
                    color: context.textSecondary,
                    fontFamily: 'Lato',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.error, size: 20),
            onPressed: () => provider.removeFile(file),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}