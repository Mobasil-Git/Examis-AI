import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../view_models/assessment_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../repository/export_repository.dart';
import '../../utils/responsive_ui.dart';

class AssessmentPreviewView extends StatelessWidget {
  const AssessmentPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final data = vm.generatedAssessment;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Rule: AppBar Primary colored in light mode
        backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Preview",
          style: TextStyle(color: Colors.white, fontFamily: 'Lato', fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.widthPercent(0.04)),
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
        padding: EdgeInsets.all(context.widthPercent(0.05)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontSize: context.isMobile ? 22 : 26, fontWeight: FontWeight.bold, height: 1.3),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            Text(
              "Review your generated questions before exporting.",
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: context.isMobile ? 14 : 16),
            ),


            if (scenarios.isNotEmpty) ...[
              SizedBox(height: context.heightPercent(0.02)),
              _buildSectionHeader(context, "Scenarios & Code Blocks", colorScheme),
              ...scenarios.asMap().entries.map((entry) {
                int index = entry.key + 1;
                Map<String, dynamic> scData = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
                  padding: EdgeInsets.all(context.widthPercent(0.04)),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Scenario $index (${scData['marks']} Marks)", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 16 : 18)),
                      SizedBox(height: context.heightPercent(0.01)),
                      Text(scData['text'].toString(), style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'monospace', fontSize: context.isMobile ? 14 : 16)),
                    ],
                  ),
                );
              }),
            ],

            if (mcqs.isNotEmpty) ...[
              _buildSectionHeader(context, "Multiple Choice (${mcqs.length})", colorScheme),
              ...mcqs.asMap().entries.map((entry) => _buildMCQCard(entry.key, entry.value, context, vm, colorScheme, theme)),
            ],
            if (fillBlanks.isNotEmpty) ...[
              SizedBox(height: context.heightPercent(0.02)),
              _buildSectionHeader(context, "Fill in the Blanks (${fillBlanks.length})", colorScheme),
              ...fillBlanks.asMap().entries.map((entry) => _buildFillBlankCard(entry.key, entry.value, context, vm, colorScheme)),
            ],
            if (shortQs.isNotEmpty) ...[
              SizedBox(height: context.heightPercent(0.02)),
              _buildSectionHeader(context, "Short Answer (${shortQs.length})", colorScheme),
              ...shortQs.asMap().entries.map((entry) => _buildShortQCard(entry.key, entry.value, context, vm, colorScheme, theme)),
            ],
            if (longQs.isNotEmpty) ...[
              SizedBox(height: context.heightPercent(0.02)),
              _buildSectionHeader(context, "Long Essay (${longQs.length})", colorScheme),
              ...longQs.asMap().entries.map((entry) => _buildLongQCard(entry.key, entry.value, context, vm, colorScheme)),
            ],

            if (diagramQs.isNotEmpty) ...[
              SizedBox(height: context.heightPercent(0.02)),
              _buildSectionHeader(context, "Diagrams & Visuals (${diagramQs.length})", colorScheme),
              ...diagramQs.asMap().entries.map((entry) {
                final diagram = entry.value;
                final int displayIndex = entry.key + 1;

                return Container(
                  margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
                  padding: EdgeInsets.all(context.widthPercent(0.04)),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withAlpha(50)),
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
                              style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontSize: context.isMobile ? 16 : 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(width: context.widthPercent(0.02)),
                          Text("[${diagram['marks']} Marks]", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      if (diagram['target_clo'] != null && diagram['target_clo'].toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.heightPercent(0.005), bottom: context.heightPercent(0.01)),
                          child: Text(diagram['target_clo'], style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant)),
                        ),
                      SizedBox(height: context.heightPercent(0.015)),
                      if (diagram['image_url'] != null && diagram['image_url'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            diagram['image_url'],
                            width: double.infinity,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: context.heightPercent(0.12),
                                child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: context.heightPercent(0.12),
                              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                              child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40)),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.02), top: context.heightPercent(0.01)),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: colorScheme.primary, fontFamily: 'Lato', fontSize: context.isMobile ? 14 : 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMCQCard(int listIndex, Map<String, dynamic> questionData, BuildContext context, AssessmentViewModel vm, ColorScheme colorScheme, ThemeData theme) {
    final bool isRegenerating = vm.isRegenerating("mcqs", listIndex);
    final int displayIndex = listIndex + 1;
    final List<dynamic> options = questionData['options'] ?? [];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: isRegenerating
          ? _buildLoadingCard(context, colorScheme)
          : Container(
        key: ValueKey(questionData['question']),
        margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
        padding: EdgeInsets.all(context.widthPercent(0.04)),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline.withAlpha(50))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text("$displayIndex. ${questionData['question']}", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontSize: context.isMobile ? 16 : 18, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.primary, size: 20),
                  onPressed: () => vm.regenerateSingleItem(context, "mcqs", listIndex),
                  tooltip: "Regenerate Question",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: context.heightPercent(0.015)),
            ...options.map((option) => Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(0.01)),
              child: Text(option.toString(), style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: context.isMobile ? 14 : 16)),
            )),
            Divider(color: colorScheme.outline.withAlpha(50), height: context.heightPercent(0.03)),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                SizedBox(width: context.widthPercent(0.02)),
                Expanded(child: Text("Answer: ${questionData['correctAnswer']}", style: TextStyle(color: Colors.green, fontFamily: 'Lato', fontSize: context.isMobile ? 14 : 16, fontWeight: FontWeight.w600))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortQCard(int listIndex, Map<String, dynamic> questionData, BuildContext context, AssessmentViewModel vm, ColorScheme colorScheme, ThemeData theme) {
    final bool isRegenerating = vm.isRegenerating("shortQuestions", listIndex);
    final int displayIndex = listIndex + 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: isRegenerating
          ? _buildLoadingCard(context, colorScheme)
          : Container(
        key: ValueKey(questionData['question']),
        margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
        padding: EdgeInsets.all(context.widthPercent(0.04)),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline.withAlpha(50))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text("$displayIndex. ${questionData['question']}", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontSize: context.isMobile ? 16 : 18, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.primary, size: 20),
                  onPressed: () => vm.regenerateSingleItem(context, "shortQuestions", listIndex),
                  tooltip: "Regenerate Question",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: context.heightPercent(0.015)),
            Container(
              padding: EdgeInsets.all(context.widthPercent(0.03)),
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Text("Ideal Answer: ${questionData['idealAnswer']}", style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: context.isMobile ? 14 : 16, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLongQCard(int listIndex, Map<String, dynamic> questionData, BuildContext context, AssessmentViewModel vm, ColorScheme colorScheme) {
    final bool isRegenerating = vm.isRegenerating("longQuestions", listIndex);
    final int displayIndex = listIndex + 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: isRegenerating
          ? _buildLoadingCard(context, colorScheme)
          : Container(
        key: ValueKey(questionData['question']),
        margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
        padding: EdgeInsets.all(context.widthPercent(0.04)),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline.withAlpha(50))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text("$displayIndex. ${questionData['question']}", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontSize: context.isMobile ? 16 : 18, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.primary, size: 20),
                  onPressed: () => vm.regenerateSingleItem(context, "longQuestions", listIndex),
                  tooltip: "Regenerate Question",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: context.heightPercent(0.015)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.widthPercent(0.03)),
              decoration: BoxDecoration(color: colorScheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: colorScheme.primary.withAlpha(50))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Grading Rubric:", style: TextStyle(color: colorScheme.primary, fontFamily: 'Lato', fontSize: context.isMobile ? 12 : 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: context.heightPercent(0.005)),
                  Text(questionData['gradingRubric'] ?? "", style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: context.isMobile ? 14 : 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      key: const ValueKey("loading"),
      height: context.heightPercent(0.2),
      margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.primary.withAlpha(100))),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/lottie_animations/AI.json', height: context.heightPercent(0.08)),
            SizedBox(height: context.heightPercent(0.016)),
            Text("AI is cooking a new question...", style: TextStyle(color: colorScheme.primary, fontFamily: 'Lato', fontWeight: FontWeight.w600)),
            SizedBox(height: context.heightPercent(0.015)),
            SizedBox(width: context.widthPercent(0.25), child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(color: colorScheme.primary, minHeight: 3))),
          ],
        ),
      ),
    );
  }

  Widget _buildFillBlankCard(int listIndex, Map<String, dynamic> questionData, BuildContext context, AssessmentViewModel vm, ColorScheme colorScheme) {
    final bool isRegenerating = vm.isRegenerating("fillInTheBlanks", listIndex);
    final int displayIndex = listIndex + 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: isRegenerating
          ? _buildLoadingCard(context, colorScheme)
          : Container(
        key: ValueKey(questionData['question']),
        margin: EdgeInsets.only(bottom: context.heightPercent(0.02)),
        padding: EdgeInsets.all(context.widthPercent(0.04)),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline.withAlpha(50))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text("$displayIndex. ${questionData['question']}", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontSize: context.isMobile ? 16 : 18, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: colorScheme.primary, size: 20),
                  onPressed: () => vm.regenerateSingleItem(context, "fillInTheBlanks", listIndex),
                  tooltip: "Regenerate Question",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: context.heightPercent(0.015)),
            Row(
              children: [
                const Icon(Icons.edit_note, color: Colors.blueAccent, size: 20),
                SizedBox(width: context.widthPercent(0.02)),
                Expanded(child: Text("Answer: ${questionData['answer']}", style: TextStyle(color: Colors.blueAccent, fontFamily: 'Lato', fontSize: context.isMobile ? 14 : 16, fontWeight: FontWeight.w600))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.heightPercent(0.065),
        decoration: BoxDecoration(color: color.withAlpha(20), border: Border.all(color: color.withAlpha(100)), borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: context.widthPercent(0.02)),
            Text(title, style: TextStyle(color: color, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 15 : 17)),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelectionBottomSheet(BuildContext pageContext, Map<String, dynamic> data) {
    bool showCloTags = false;
    final theme = Theme.of(pageContext);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: pageContext,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext stateContext, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.all(pageContext.widthPercent(0.05)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Institute Template", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontSize: pageContext.isMobile ? 18 : 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: pageContext.heightPercent(0.01)),
                  Text("Choose which header to apply to this exam.", style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: pageContext.isMobile ? 14 : 16)),
                  SizedBox(height: pageContext.heightPercent(0.02)),
                  Container(
                    decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorScheme.outline.withAlpha(50))),
                    child: SwitchListTile(
                      value: showCloTags,
                      activeColor: colorScheme.primary,
                      title: Text("Include CLO Tags", style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: pageContext.isMobile ? 16 : 18)),
                      subtitle: Text("Append learning objectives (e.g., [CLO 1]) to the end of each question.", style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: pageContext.isMobile ? 12 : 14)),
                      onChanged: (bool value) {
                        setSheetState(() {
                          showCloTags = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: pageContext.heightPercent(0.02)),
                  Flexible(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: Supabase.instance.client.from('institutes').select().order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(padding: EdgeInsets.all(pageContext.widthPercent(0.08)), child: const Center(child: CircularProgressIndicator()));
                        }
                        if (snapshot.hasError) {
                          return Padding(padding: EdgeInsets.all(pageContext.widthPercent(0.04)), child: Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: colorScheme.error))));
                        }

                        final institutes = snapshot.data ?? [];
                        if (institutes.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: pageContext.heightPercent(0.04)),
                            child: Center(child: Text("No templates found.\nPlease add an institute in your Profile.", textAlign: TextAlign.center, style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato'))),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: institutes.length,
                          itemBuilder: (context, index) {
                            final institute = institutes[index];
                            return ListTile(
                              leading: Icon(Icons.business, color: colorScheme.primary),
                              title: Text(institute['institute_name'], style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              tileColor: colorScheme.surface,
                              contentPadding: EdgeInsets.symmetric(horizontal: pageContext.widthPercent(0.04), vertical: pageContext.heightPercent(0.005)),
                              onTap: () async {
                                Navigator.pop(bottomSheetContext);
                                _showSmartLoadingDialog(pageContext);

                                final String selectedUrl = institute['template_url'];
                                final vm = pageContext.read<AssessmentViewModel>();

                                final success = await ExportRepository().exportToWord(
                                  data,
                                  selectedUrl,
                                  showCloTags,
                                  vm.selectedExamType,
                                  vm.currentTargetMarks,
                                  vm.selectedCourseTitle ?? "Unknown Course",
                                  vm.courseCreditHours,
                                  vm.selectedDepartmentName ?? "General",
                                );

                                if (pageContext.mounted) {
                                  Navigator.pop(pageContext);
                                  if (!success) {
                                    ScaffoldMessenger.of(pageContext).showSnackBar(
                                      SnackBar(content: const Text("Failed to export DOCX. Server might be down.", style: TextStyle(color: Colors.white)), backgroundColor: colorScheme.error),
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

  void _showSmartLoadingDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const _SmartLoadingDialog();
      },
    );
  }
}

class _SmartLoadingDialog extends StatefulWidget {
  const _SmartLoadingDialog();

  @override
  State<_SmartLoadingDialog> createState() => _SmartLoadingDialogState();
}

class _SmartLoadingDialogState extends State<_SmartLoadingDialog> {
  String _message = "Generating Document... 📄";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _message = "Waking up the server...\nThis may take up to a minute. ☕";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(context.widthPercent(0.06)),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            SizedBox(height: context.heightPercent(0.03)),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 16 : 18),
            ),
          ],
        ),
      ),
    );
  }
}