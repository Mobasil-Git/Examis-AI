import 'package:examis_ai/pages/assessment_preview_page.dart';
import 'package:examis_ai/provider/assessment_provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert'; // Required to convert your history into a JSON file
import 'package:examis_ai/services/google_drive_service.dart'; // Adjust path if you named the folder differently

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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. THE GOOGLE DRIVE BACKUP SECTION ---
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
                        // 1. Grab the list of assessments
                        final historyList = historyProvider.savedAssessments;

                        // 2. Prevent empty backups
                        if (historyList.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("No assessments to backup yet! Generate some first."),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        // 3. Show a "loading" message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Backing up to Google Drive... Please wait ☁️"),
                            duration: Duration(seconds: 3), // Gives it time to upload
                          ),
                        );

                        // 4. Format the data into a beautiful, readable JSON string
                        // Using JsonEncoder with indents makes the file human-readable if they open it!
                        final String jsonContent = const JsonEncoder.withIndent('  ').convert(historyList);

                        // Create a unique filename based on today's date
                        final String dateString = DateTime.now().toIso8601String().split('T').first;
                        final String fileName = "Examis_AI_Backup_$dateString.json";

                        // 5. Call the Drive Service!
                        final driveService = GoogleDriveService();
                        final success = await driveService.backupFileToDrive(
                          fileName: fileName,
                          fileContent: jsonContent,
                        );

                        // 6. Show the final result
                        if (context.mounted) {
                          // Hide the "loading" snackbar instantly
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? "Backup Successful! 🚀 Saved to 'Examis AI' folder."
                                    : "Backup Failed. Please ensure you logged in with Google.",
                              ),
                              backgroundColor: success ? AppColors.success : AppColors.error,
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
                child: history.isEmpty
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
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final title = item['title'] ?? "Untitled Assessment";

                          // Calculate total questions for the subtitle
                          final mcqCount = (item['mcqs'] as List?)?.length ?? 0;
                          final shortCount =
                              (item['shortQuestions'] as List?)?.length ?? 0;
                          final longCount =
                              (item['longQuestions'] as List?)?.length ?? 0;
                          final totalQs = mcqCount + shortCount + longCount;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.border,
                              ), // Perfectly flat!
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
                                  "$totalQs Questions Generated",
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
                                  // Ask provider to delete it
                                  historyProvider.deleteAssessment(index);
                                },
                              ),
                              onTap: () {
                                // 1. Load the old data into the AssessmentProvider
                                context
                                    .read<AssessmentProvider>()
                                    .loadPastAssessment(item);
                                // 2. Navigate to the preview screen
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
