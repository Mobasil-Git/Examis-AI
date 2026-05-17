import 'package:examis_ai/pages/assessment_preview_page.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:examis_ai/services/google_drive_service.dart';
import 'package:intl/intl.dart'; // <-- REQUIRED FOR DATE FORMATTING

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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
          "History",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          final history = historyProvider.savedAssessments;

          // 🚀 FORCE SORT BY DATE (Newest First)
          final sortedHistory = List<Map<String, dynamic>>.from(history);
          sortedHistory.sort((a, b) {
            // Safely parse dates, default to 0 if missing
            final dateA = a['created_at'] != null
                ? DateTime.tryParse(a['created_at']) ??
                      DateTime.fromMillisecondsSinceEpoch(0)
                : DateTime.fromMillisecondsSinceEpoch(0);
            final dateB = b['created_at'] != null
                ? DateTime.tryParse(b['created_at']) ??
                      DateTime.fromMillisecondsSinceEpoch(0)
                : DateTime.fromMillisecondsSinceEpoch(0);

            return dateB.compareTo(dateA); // Descending order
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surface,
                  border: Border(bottom: BorderSide(color: context.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cloud Backup",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontFamily: 'Lato',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Safely store your generated assessments in your personal Google Drive so you never lose them.",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontFamily: 'Lato',
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final historyList = historyProvider.savedAssessments;
                        if (historyList.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "No assessments to backup yet! Generate some first.",
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Backing up to Google Drive... Please wait ☁️",
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );

                        final String jsonContent = const JsonEncoder.withIndent(
                          '  ',
                        ).convert(historyList);
                        final String dateString = DateTime.now()
                            .toIso8601String()
                            .split('T')
                            .first;
                        final String fileName =
                            "Examis_AI_Backup_$dateString.json";

                        final driveService = GoogleDriveService();
                        final success = await driveService.backupFileToDrive(
                          fileName: fileName,
                          fileContent: jsonContent,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? "Backup Successful! 🚀 Saved to 'Examis AI' folder."
                                    : "Backup Failed. Please ensure you logged in with Google.",
                              ),
                              backgroundColor: success
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withAlpha(20),
                          border: Border.all(
                            color: Colors.blueAccent.withAlpha(100),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_to_drive,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
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

              // --- 2. THE LOCAL HISTORY LIST ---
              Expanded(
                child: sortedHistory.isEmpty
                    ? Center(
                        child: Text(
                          "No assessments generated yet.",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontFamily: 'Lato',
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: sortedHistory.length,
                        itemBuilder: (context, index) {
                          final item = sortedHistory[index];
                          final title = item['title'] ?? "Untitled Assessment";

                          String formattedDate = "Unknown Date";
                          if (item['created_at'] != null) {
                            try {
                              DateTime date = DateTime.parse(
                                item['created_at'],
                              ).toLocal();
                              formattedDate = DateFormat(
                                'MMM dd, yyyy • h:mm a',
                              ).format(date);
                            } catch (e) {
                              formattedDate = "Recently Generated";
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  // 🚀 INJECTED THE TIMESTAMP HERE
                                  formattedDate,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontFamily: 'Lato',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                ),
                                onPressed: () {
                                  // Use the index from the ORIGINAL list to avoid deleting the wrong item
                                  int originalIndex = history.indexOf(item);
                                  historyProvider.deleteAssessment(
                                    context,
                                    originalIndex,
                                  );
                                },
                              ),
                              onTap: () {
                                context
                                    .read<AssessmentProvider>()
                                    .loadPastAssessment(item);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AssessmentPreviewPage(),
                                  ),
                                );
                              },
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
