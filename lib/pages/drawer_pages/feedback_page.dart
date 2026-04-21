import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? context.surface : AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Feedback",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              color: AppColors.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
             Text(
              "We'd love to hear from you!",
              style: TextStyle(
                color: context.textPrimary,
                fontFamily: 'Lato',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
             Text(
              "Found a bug or have a feature request? Let us know how we can make Examis AI even better for your classroom.",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Flat Feedback Text Area
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 6,
                style:  TextStyle(
                  fontFamily: 'Lato',
                  color: context.textPrimary,
                ),
                decoration:  InputDecoration(
                  hintText: "Type your feedback here...",
                  hintStyle: TextStyle(
                    color: context.textSecondary,
                    fontFamily: 'Lato',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- REAL FUNCTIONAL SUBMIT BUTTON ---
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus();

                    final message = _feedbackController.text.trim();
                    if (message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter some feedback first."),
                        ),
                      );
                      return;
                    }

                    // Call Supabase!
                    final success = await authProvider.submitFeedback(
                      context,
                      message,
                    );

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Thank you for your feedback!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context); // Send them back to the dashboard
                    }
                  },
                  child: Container(
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      // Show loading indicator if Supabase is processing
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              "Submit Feedback",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
