import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

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
          "About Us",
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // App Logo / Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Image.asset("assets/splash_screen_assets/ExamisAI.png",scale: 30,)
            ),
            const SizedBox(height: 16),

             Text(
              "Examis AI",
              style: TextStyle(
                color: context.textPrimary,
                fontFamily: 'Lato',
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
             Text(
              "Version 1.0.0",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            // Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Our Mission",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lato',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Examis AI is a Smart Assessment Portal designed to save educators hours of manual prep time. Crafted with a passion for clean UI/UX design and powerful Artificial Intelligence, this tool represents the future of automated curriculum management.",
                    style: TextStyle(
                      color: context.textSecondary,
                      fontFamily: 'Lato',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Whether you are generating MCQs, short answers, or complex essay prompts, our goal is to streamline your workflow so you can focus on what matters most: teaching.",
                    style: TextStyle(
                      color: context.textSecondary,
                      fontFamily: 'Lato',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Developer / Contact Info
             Text(
              "Developed with Flutter & AI",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
             Text(
              "© 2026 Examis AI",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
