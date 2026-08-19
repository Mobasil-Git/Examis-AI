import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/history_view_model.dart';
import '../../view_models/assessment_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../assessment_views/assessment_preview_view.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeVM = context.watch<ThemeViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Dynamic AppBar coloring
        backgroundColor: themeVM.isDarkMode ? colorScheme.surface : colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "History",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<HistoryViewModel>(
        builder: (context, historyVM, child) {
          final history = historyVM.savedAssessments;

          final sortedHistory = List<Map<String, dynamic>>.from(history);
          sortedHistory.sort((a, b) {
            final dateA = a['created_at'] != null
                ? DateTime.tryParse(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0)
                : DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b['created_at'] != null
                ? DateTime.tryParse(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0)
                : DateTime.fromMillisecondsSinceEpoch(0);

            return dateB.compareTo(dateA);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(context.widthPercent(0.05)),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(bottom: BorderSide(color: colorScheme.outline.withAlpha(50))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cloud Backup",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Lato',
                        fontSize: context.isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.01)),
                    Text(
                      "Safely store your generated assessments in your personal Google Drive so you never lose them.",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'Lato',
                        fontSize: context.isMobile ? 13 : 15,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.02)),
                    GestureDetector(
                      onTap: () async {
                        if (historyVM.savedAssessments.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("No assessments to backup yet! Generate some first."),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Backing up to Google Drive... Please wait ☁️"),
                            duration: Duration(seconds: 3),
                          ),
                        );

                        final String dateString = DateTime.now().toIso8601String().split('T').first;
                        final String fileName = "Examis_AI_Backup_$dateString.json";

                        final success = await historyVM.backupToDrive(fileName);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? "Backup Successful! 🚀 Saved to 'Examis AI' folder."
                                    : "Backup Failed. Please ensure you logged in with Google.",
                              ),
                              backgroundColor: success ? Colors.green : colorScheme.error,
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: context.heightPercent(0.06),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withAlpha(20),
                          border: Border.all(
                            color: Colors.blueAccent.withAlpha(100),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_to_drive, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Backup to Google Drive",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: sortedHistory.isEmpty
                    ? Center(
                  child: Text(
                    "No assessments generated yet.",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'Lato',
                      fontSize: context.isMobile ? 16 : 18,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(context.widthPercent(0.05)),
                  itemCount: sortedHistory.length,
                  itemBuilder: (context, index) {
                    final item = sortedHistory[index];
                    final title = item['title'] ?? "Untitled Assessment";

                    String formattedDate = "Unknown Date";
                    if (item['created_at'] != null) {
                      try {
                        DateTime date = DateTime.parse(item['created_at']).toLocal();
                        formattedDate = DateFormat('MMM dd, yyyy • h:mm a').format(date);
                      } catch (e) {
                        formattedDate = "Recently Generated";
                      }
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: context.heightPercent(0.015)),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outline.withAlpha(50)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04), vertical: context.heightPercent(0.01)),
                          leading: Container(
                            padding: EdgeInsets.all(context.widthPercent(0.025)),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.description_outlined, color: colorScheme.primary),
                          ),
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: context.isMobile ? 16 : 18,
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: context.heightPercent(0.005)),
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontFamily: 'Lato',
                                fontSize: context.isMobile ? 13 : 15,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: colorScheme.error),
                            onPressed: () {
                              int originalIndex = history.indexOf(item);
                              historyVM.deleteAssessment(context, originalIndex);
                            },
                          ),
                          onTap: () {
                            context.read<AssessmentViewModel>().loadPastAssessment(item);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AssessmentPreviewView()),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}