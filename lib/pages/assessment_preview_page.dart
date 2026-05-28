import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/export_service.dart';

class AssessmentPreviewPage extends StatelessWidget {
  const AssessmentPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final data = provider.generatedAssessment;
    final themeProvider = context.watch<ThemeProvider>();
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("No assessment data found.")),
      );
    }

    final String title = data['title'] ?? "Generated Assessment";
    final List<dynamic> mcqs = data['mcqs'] ?? [];
    final List<dynamic> shortQs = data['shortQuestions'] ?? [];
    final List<dynamic> longQs = data['longQuestions'] ?? [];
    final List<dynamic> fillBlanks = data['fillInTheBlanks'] ?? [];
    final List<dynamic> scenarios = data['custom_scenarios'] ?? [];
    final List<dynamic> diagramQs = data['diagram_questions'] ?? [];


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

            if (scenarios.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Scenarios & Code Blocks"),
              ...scenarios
                  .asMap()
                  .entries
                  .map((entry) {
                int index = entry.key + 1;
                Map<String, dynamic> scData = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Scenario $index (${scData['marks']} Marks)",
                        style: TextStyle(
                          color: context.textPrimary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scData['text'].toString(),
                        style: TextStyle(
                          color: context.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (mcqs.isNotEmpty) ...[
              _buildSectionHeader("Multiple Choice (${mcqs.length})"),
              ...mcqs
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                    _buildMCQCard(entry.key, entry.value, context, provider),
              ),
            ],
            if (fillBlanks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Fill in the Blanks (${fillBlanks.length})"),
              ...fillBlanks
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                    _buildFillBlankCard(
                      entry.key,
                      entry.value,
                      context,
                      provider,
                    ),
              ),
            ],
            if (shortQs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Short Answer (${shortQs.length})"),
              ...shortQs
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                    _buildShortQCard(entry.key, entry.value, context, provider),
              ),
            ],
            if (longQs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Long Essay (${longQs.length})"),
              ...longQs
                  .asMap()
                  .entries
                  .map(
                    (entry) =>
                    _buildLongQCard(entry.key, entry.value, context, provider),
              ),
            ],

            if (diagramQs.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader("Diagrams & Visuals (${diagramQs.length})"),
              ...diagramQs
                  .asMap()
                  .entries
                  .map((entry) {
                final diagram = entry.value;
                final int displayIndex = entry.key + 1;

                return Container(
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
                              "$displayIndex. ${diagram['question'] ?? ""}",
                              style: TextStyle(
                                color: context.textPrimary,
                                fontFamily: 'Lato',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "[${diagram['marks']} Marks]",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      if (diagram['target_clo'] != null &&
                          diagram['target_clo']
                              .toString()
                              .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                          child: Text(
                            diagram['target_clo'],
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: context.textSecondary,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      if (diagram['image_url'] != null &&
                          diagram['image_url']
                              .toString()
                              .isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            diagram['image_url'],
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const SizedBox(
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: context.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

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

  Widget _buildMCQCard(int listIndex,
      Map<String, dynamic> questionData,
      BuildContext context,
      AssessmentProvider provider,) {
    final bool isRegenerating = provider.isRegenerating("mcqs", listIndex);
    final int displayIndex = listIndex + 1;
    final List<dynamic> options = questionData['options'] ?? [];

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
                  onPressed: () =>
                      provider.regenerateSingleItem(
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
                  (option) =>
                  Padding(
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

  Widget _buildShortQCard(int listIndex,
      Map<String, dynamic> questionData,
      BuildContext context,
      AssessmentProvider provider,) {
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
                  onPressed: () =>
                      provider.regenerateSingleItem(
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

  Widget _buildLongQCard(int listIndex,
      Map<String, dynamic> questionData,
      BuildContext context,
      AssessmentProvider provider,) {
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
                  onPressed: () =>
                      provider.regenerateSingleItem(
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

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      key: const ValueKey("loading"),
      height: 180,
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

  Widget _buildFillBlankCard(int listIndex,
      Map<String, dynamic> questionData,
      BuildContext context,
      AssessmentProvider provider,) {
    final bool isRegenerating = provider.isRegenerating(
      "fillInTheBlanks",
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
                  onPressed: () =>
                      provider.regenerateSingleItem(
                        context,
                        "fillInTheBlanks",
                        listIndex,
                      ),
                  tooltip: "Regenerate Question",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Answer: ${questionData['answer']}",
                    style: const TextStyle(
                      color: Colors.blueAccent,
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

  Widget _buildFlatButton(BuildContext context, {
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

  void _showTemplateSelectionBottomSheet(BuildContext context,
      Map<String, dynamic> data,) {
    bool showCloTags = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
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
                        setSheetState(() {
                          showCloTags = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

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
                                Navigator.pop(bottomSheetContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Generating Word Document... 📄",
                                    ),
                                  ),
                                );

                                final String selectedUrl =
                                institute['template_url'];
                                final provider = context.read<
                                    AssessmentProvider>();

                                final success = await ExportService()
                                    .exportToWord(
                                  data,
                                  selectedUrl,
                                  showCloTags,
                                  provider.selectedExamType,
                                  provider.currentTargetMarks,
                                  provider.selectedCourseTitle ??
                                      "Unknown Course",
                                  provider.courseCreditHours,
                                  provider.selectedDepartmentName ?? "BSCS",
                                );

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
