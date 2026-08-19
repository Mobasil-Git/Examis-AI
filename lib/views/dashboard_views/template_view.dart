import 'package:examisai/utils/theme/app_colors.dart';
import 'package:examisai/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../resources/components/create_institute_form.dart';
import '../../view_models/template_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../utils/responsive_ui.dart';

class TemplatesView extends StatefulWidget {
  const TemplatesView({super.key});

  @override
  State<TemplatesView> createState() => _TemplatesViewState();
}

class _TemplatesViewState extends State<TemplatesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateViewModel>().fetchTemplates();
    });
  }

  void _showUploadSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery
                  .of(ctx)
                  .viewInsets
                  .bottom,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25)),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.widthPercent(0.06)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upload New Template",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 18 : 20,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  CreateInstituteForm(
                    onSuccess: () {
                      Navigator.pop(ctx);
                      context.read<TemplateViewModel>().fetchTemplates();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final templateVM = context.watch<TemplateViewModel>();
    final themeVM = context.watch<ThemeViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Dynamic AppBar coloring implemented
        backgroundColor: themeVM.isDarkMode ? colorScheme.surface : colorScheme
            .primary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "My Templates",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: context.heightPercent(0.12)),
        child: FloatingActionButton.extended(
          onPressed: () => _showUploadSheet(context),
          backgroundColor: colorScheme.primary,
          elevation: 0,
          highlightElevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            "Upload",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: templateVM.isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : templateVM.templates.isEmpty
          ? _buildEmptyState(context, colorScheme)
          : _buildTemplateList(context, templateVM, colorScheme),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.widthPercent(0.08)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.widthPercent(0.06)),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  Icons.document_scanner_outlined,
                  size: context.isMobile ? 64 : 80,
                  color: colorScheme.primary
              ),
            ),
            SizedBox(height: context.heightPercent(0.03)),
            Text(
              "No Templates Yet",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: context.isMobile ? 20 : 24,
              ),
            ),
            SizedBox(height: context.heightPercent(0.015)),
            Text(
              "Upload custom Word document headers with your school's logo and details. We'll automatically stitch them onto your generated exams.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: context.isMobile ? 14 : 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList(BuildContext context, TemplateViewModel vm,
      ColorScheme colorScheme) {
    return ListView.builder(
      padding: EdgeInsets.all(context.widthPercent(0.06)),
      itemCount: vm.templates.length,
      itemBuilder: (context, index) {
        final template = vm.templates[index];
        final isLastItem = index == vm.templates.length - 1;

        return Padding(
          padding: EdgeInsets.only(
              bottom: isLastItem ? context.heightPercent(0.15) : context
                  .heightPercent(0.02)),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withAlpha(50)),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: context.widthPercent(0.04),
                    vertical: context.heightPercent(0.01)
                ),
                leading: Container(
                  padding: EdgeInsets.all(context.widthPercent(0.025)),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                      Icons.description_rounded, color: colorScheme.primary),
                ),
                title: Text(
                  template['institute_name'] ?? "Untitled Template",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Uploaded Document",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                      Icons.delete_outline_rounded, color: colorScheme.error),
                  onPressed: () async {
                    final rawId = template['id'];
                    if (rawId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Deleting template..."),
                            duration: Duration(seconds: 1)),
                      );

                      bool success = await vm.deleteTemplate(rawId);

                      if (success && context.mounted) {
                        Utils.showSnackBar(
                            context, 'Template Deleted Successfully',
                            AppColors.success);
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}