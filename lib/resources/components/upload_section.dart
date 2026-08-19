import 'dart:math' as math;
import 'dart:io'; // Added for native file operations
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
    final iconHeight = context.heightPercent(0.06);
    final iconWidth = context.widthPercent(0.15);

    final assessmentVM = context.watch<AssessmentViewModel>();
    final files = assessmentVM.selectedFiles;
    final hasFiles = files.isNotEmpty;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(15),
        color: colorScheme.primary,
        strokeWidth: 2,
        dashPattern: const [8.0, 8.0],
      ),
      child: Container(
        height: context.heightPercent(0.24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(context.widthPercent(0.03)),
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
                      color: colorScheme.onSurface,
                      fontFamily: "Lato",
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 15 : 17,
                    ),
                  ),
                  Container(
                    height: context.heightPercent(0.035),
                    width: context.widthPercent(0.15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: colorScheme.primary.withAlpha(35),
                    ),
                    child: Center(
                      child: Text(
                        "Step 1",
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
              SizedBox(height: context.heightPercent(0.015)),
              Expanded(
                child: hasFiles
                    ? _buildFileList(context, assessmentVM, colorScheme)
                    : _buildEmptyState(context, iconHeight, iconWidth, assessmentVM, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double iconHeight, double iconWidth, AssessmentViewModel vm, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => vm.pickFile(context),
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
          SizedBox(height: context.heightPercent(0.015)),
          Text(
            "Tap here to browse files",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              fontSize: context.isMobile ? 16 : 18,
            ),
          ),
          SizedBox(height: context.heightPercent(0.005)),
          Text(
            "Max 3 files (10MB limit per file)",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, AssessmentViewModel vm, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...vm.selectedFiles.map((file) => _buildFileTile(file, vm, context, colorScheme)).toList(),
          if (vm.canAddMoreFiles)
            Padding(
              padding: EdgeInsets.only(top: context.heightPercent(0.01)),
              child: TextButton.icon(
                onPressed: () => vm.pickFile(context),
                icon: Icon(Icons.add_circle_outline, color: colorScheme.primary, size: 20),
                label: Text(
                  "Add Another File",
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.widthPercent(0.04),
                    vertical: context.heightPercent(0.01),
                  ),
                  backgroundColor: colorScheme.primary.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileTile(PlatformFile file, AssessmentViewModel vm, BuildContext context, ColorScheme colorScheme) {
    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = colorScheme.onSurfaceVariant;

    // Securely extract the file extension and size natively
    final String extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    final int fileSize = file.path != null ? File(file.path!).lengthSync() : 0;

    if (extension == 'pdf') {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.redAccent;
    } else if (extension == 'docx' || extension == 'doc') {
      fileIcon = Icons.description;
      iconColor = Colors.blueAccent;
    } else if (extension == 'pptx' || extension == 'ppt') {
      fileIcon = Icons.slideshow;
      iconColor = Colors.orangeAccent;
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.heightPercent(0.01)),
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPercent(0.03),
        vertical: context.heightPercent(0.01),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(fileIcon, color: iconColor, size: 24),
          SizedBox(width: context.widthPercent(0.03)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB", // Fallback to natively read size
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colorScheme.error, size: 20),
            onPressed: () => vm.removeFile(file),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}