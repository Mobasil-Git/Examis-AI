import 'package:examis_ai/componenets/widget/create_institute_form.dart';
import 'package:examis_ai/provider/template_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {

  @override
  void initState() {
    super.initState();
    // 🚀 Fetch the user's templates the moment this tab is opened!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().fetchTemplates();
    });
  }

  // --- The sleek Bottom Sheet for uploading ---
  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: context.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CreateInstituteForm(
                onSuccess: () {
                  Navigator.pop(ctx);
                  context.read<TemplateProvider>().fetchTemplates();
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
    final themeProvider = context.watch<ThemeProvider>();
    final templateProvider = context.watch<TemplateProvider>();

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode
            ? context.surface
            : AppColors.primary,
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
        padding: const EdgeInsets.only(bottom: 90), // Bumper to clear the Master Nav Bar
        child: FloatingActionButton.extended(
          onPressed: () => _showUploadSheet(context),
          backgroundColor: AppColors.primary,
          elevation: 0,
          highlightElevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            "Upload",
            style: TextStyle(color: Colors.white, fontFamily: 'Lato', fontWeight: FontWeight.bold),
          ),
        ),
      ),

      body: templateProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : templateProvider.templates.isEmpty
          ? _buildEmptyState(context)
          : _buildTemplateList(context, templateProvider),
    );
  }

  // --- 🎨 The Premium Empty State ---
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              "No Templates Yet",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Upload custom Word document headers with your school's logo and details. We'll automatically stitch them onto your generated exams.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 📝 The List View (Mapped to Supabase columns) ---
  Widget _buildTemplateList(BuildContext context, TemplateProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: provider.templates.length,
      itemBuilder: (context, index) {
        final template = provider.templates[index];
        final isLastItem = index == provider.templates.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastItem ? 120.0 : 16.0), // Nav Bar Bumper!
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(50)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded, color: AppColors.primary),
              ),
              // 🚀 Maps exactly to your Database column name!
              title: Text(
                template['institute_name'] ?? "Untitled Template",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Uploaded Document",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                onPressed: () {
                  // Pass the actual 'id' column from your Supabase table
                  if (template['id'] != null) {
                    provider.deleteTemplate(template['id']);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}