import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../utils/responsive_ui.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Dynamic AppBar coloring based on the theme rule
        backgroundColor: themeVM.isDarkMode
            ? colorScheme.surface
            : colorScheme.primary,
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
        padding: EdgeInsets.all(context.widthPercent(0.06)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.rate_review_outlined,
              color: colorScheme.primary,
              size: context.isMobile ? 48 : 56,
            ),
            SizedBox(height: context.heightPercent(0.02)),
            Text(
              "We'd love to hear from you!",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontSize: context.isMobile ? 22 : 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            Text(
              "Found a bug or have a feature request? Let us know how we can make Examis AI even better for your classroom.",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: context.isMobile ? 14 : 16,
                height: 1.4,
              ),
            ),
            SizedBox(height: context.heightPercent(0.04)),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withAlpha(50)),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 6,
                style: TextStyle(
                  fontFamily: 'Lato',
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "Type your feedback here...",
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(context.widthPercent(0.04)),
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(0.04)),
            Consumer<AuthViewModel>(
              builder: (context, authVM, child) {
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

                    final success = await authVM.submitFeedback(
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
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    height: context.heightPercent(0.065),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: authVM.isLoading
                          ? SizedBox(
                        height: context.widthPercent(0.06),
                        width: context.widthPercent(0.06),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : Text(
                        "Submit Feedback",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 16 : 18,
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