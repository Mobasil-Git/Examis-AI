import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added for fetching templates
import '../services/export_service.dart';

class AssessmentPreviewPage extends StatelessWidget {
  const AssessmentPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Grab the data from the provider
    final provider = context.watch<AssessmentProvider>();
    final data = provider.generatedAssessment;
    final themeProvider = context.watch<ThemeProvider>();

    // Safety check just in case it loads empty
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("No assessment data found.")),
      );
    }

    // Extract the lists safely (defaulting to empty lists if they don't exist)
    final String title = data['title'] ?? "Generated Assessment";
    final List<dynamic> mcqs = data['mcqs'] ?? [];
    final List<dynamic> shortQs = data['shortQuestions'] ?? [];
    final List<dynamic> longQs = data['longQuestions'] ?? [];

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode
            ? context.surface
            : AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Preview",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildFlatButton(
            context,
            title: "Export Word Document",
            icon: Icons.description_outlined,
            color: Colors.blueAccent,
            onTap: () {
              // Open the template selector
              _showTemplateSelectionBottomSheet(context, data);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Title Section ---
            Text(
              title,
              style: TextStyle(
                color: context.textPrimary,
                fontFamily: 'Lato',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Review your generated questions before exporting.",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 14,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: context.border),
            ),

            // --- Multiple Choice Section ---
            if (mcqs.isNotEmpty) ...[
              _buildSectionHeader("Multiple Choice (${mcqs.length})"),
              ...mcqs.asMap().entries.map(
                // Note: We pass the raw index (entry.key) and the provider now!
                (entry) =>
                    _buildMCQCard(entry.key, entry.value, context, provider),
              ),
            ],

            // --- Short Answer Section ---
            if (shortQs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Short Answer (${shortQs.length})"),
              ...shortQs.asMap().entries.map(
                (entry) =>
                    _buildShortQCard(entry.key, entry.value, context, provider),
              ),
            ],

            // --- Long Essay Section ---
            if (longQs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Long Essay (${longQs.length})"),
              ...longQs.asMap().entries.map(
                (entry) =>
                    _buildLongQCard(entry.key, entry.value, context, provider),
              ),
            ],

            const SizedBox(height: 40), // Extra padding at the bottom
          ],
        ),
      ),
    );
  }

  // --- Helper Methods to keep the code DRY and flat ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontFamily: 'Lato',
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMCQCard(
    int listIndex,
    Map<String, dynamic> questionData,
    BuildContext context,
    AssessmentProvider provider,
  ) {
    final bool isRegenerating = provider.isRegenerating("mcqs", listIndex);
    final int displayIndex = listIndex + 1;
    final List<dynamic> options = questionData['options'] ?? [];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: isRegenerating
          ? _buildLoadingCard(context) // Shows our custom spinner skeleton!
          : Container(
              key: ValueKey(questionData['question']),
              // Crucial for animation!
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "$displayIndex. ${questionData['question']}",
                          style: TextStyle(
                            color: context.textPrimary,
                            fontFamily: 'Lato',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // THE REFRESH BUTTON
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => provider.regenerateSingleItem(
                          context,
                          "mcqs",
                          listIndex,
                        ),
                        tooltip: "Regenerate Question",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        option.toString(),
                        style: TextStyle(
                          color: context.textSecondary,
                          fontFamily: 'Lato',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Divider(color: context.border, height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Answer: ${questionData['correctAnswer']}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontFamily: 'Lato',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildShortQCard(
    int listIndex,
    Map<String, dynamic> questionData,
    BuildContext context,
    AssessmentProvider provider,
  ) {
    final bool isRegenerating = provider.isRegenerating(
      "shortQuestions",
      listIndex,
    );
    final int displayIndex = listIndex + 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: isRegenerating
          ? _buildLoadingCard(context)
          : Container(
              key: ValueKey(questionData['question']),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "$displayIndex. ${questionData['question']}",
                          style: TextStyle(
                            color: context.textPrimary,
                            fontFamily: 'Lato',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => provider.regenerateSingleItem(
                          context,
                          "shortQuestions",
                          listIndex,
                        ),
                        tooltip: "Regenerate Question",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Ideal Answer: ${questionData['idealAnswer']}",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontFamily: 'Lato',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLongQCard(
    int listIndex,
    Map<String, dynamic> questionData,
    BuildContext context,
    AssessmentProvider provider,
  ) {
    final bool isRegenerating = provider.isRegenerating(
      "longQuestions",
      listIndex,
    );
    final int displayIndex = listIndex + 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: isRegenerating
          ? _buildLoadingCard(context)
          : Container(
              key: ValueKey(questionData['question']),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "$displayIndex. ${questionData['question']}",
                          style: TextStyle(
                            color: context.textPrimary,
                            fontFamily: 'Lato',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onPressed: () => provider.regenerateSingleItem(
                          context,
                          "longQuestions",
                          listIndex,
                        ),
                        tooltip: "Regenerate Question",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Grading Rubric:",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          questionData['gradingRubric'] ?? "",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontFamily: 'Lato',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- A nice glowing skeleton loader for when a card is regenerating ---
  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      key: const ValueKey("loading"),
      // Crucial for animation!
      height: 180,
      // Made it slightly taller to comfortably fit your asset!
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/lottie_animations/AI.json',
              height: 60,
            ),
            SizedBox(height: context.heightPercent(0.016)),
            const Text(
              "AI is cooking a new question...",
              style: TextStyle(
                color: AppColors.primary,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // A sleek, tiny loading bar to keep the "working" feel underneath the text
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  color: AppColors.primary,
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          border: Border.all(color: color.withAlpha(100)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOTTOM SHEET FOR TEMPLATE SELECTION ---
  // --- BOTTOM SHEET FOR TEMPLATE SELECTION ---
  void _showTemplateSelectionBottomSheet(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    // 1. A local variable to track the toggle switch
    bool showCloTags = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.background,
      isScrollControlled: true,
      // Prevents list clipping
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        // 2. Wrap the content in a StatefulBuilder so the toggle can animate
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Institute Template",
                    style: TextStyle(
                      color: context.textPrimary,
                      fontFamily: 'Lato',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose which header to apply to this exam.",
                    style: TextStyle(
                      color: context.textSecondary,
                      fontFamily: 'Lato',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // NEW SECTION: OBE / CLO TOGGLE SWITCH
                  // ==========================================
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: SwitchListTile(
                      value: showCloTags,
                      activeColor: AppColors.primary,
                      title: Text(
                        "Include CLO Tags",
                        style: TextStyle(
                          color: context.textPrimary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "Append learning objectives (e.g., [CLO 1]) to the end of each question.",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontFamily: 'Lato',
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (bool value) {
                        // Flips the switch inside the bottom sheet
                        setSheetState(() {
                          showCloTags = value;
                        });
                      },
                    ),
                  ),

                  // ==========================================
                  const SizedBox(height: 16),

                  // Fetch the templates from Supabase
                  Flexible(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Supabase.instance.client
                          .from('institutes')
                          .select()
                          .order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                "Error: ${snapshot.error}",
                                style: TextStyle(color: context.error),
                              ),
                            ),
                          );
                        }

                        final institutes = snapshot.data ?? [];

                        if (institutes.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(
                              child: Text(
                                "No templates found.\nPlease add an institute in your Profile.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontFamily: 'Lato',
                                ),
                              ),
                            ),
                          );
                        }

                        // Build the list of templates
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: institutes.length,
                          itemBuilder: (context, index) {
                            final institute = institutes[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.business,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                institute['institute_name'],
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tileColor: context.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              onTap: () async {
                                // 1. Close the bottom sheet
                                Navigator.pop(bottomSheetContext);

                                // 2. Show the loading snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Generating Word Document... 📄",
                                    ),
                                  ),
                                );

                                // 3. TRIGGER THE EXPORT WITH THE NEW TOGGLE VALUE!
                                final String selectedUrl =
                                    institute['template_url'];
                                final success = await ExportService()
                                    .exportToWord(
                                      data,
                                      selectedUrl,
                                      showCloTags,
                                    );

                                // 4. Handle Success/Fail
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  if (!success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          "Failed to export DOCX.",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: context.error,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
