import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/theme_view_model.dart';
import '../../utils/responsive_ui.dart';

class AboutUsView extends StatelessWidget {
  const AboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Dynamic AppBar coloring implemented
        backgroundColor: themeVM.isDarkMode
            ? colorScheme.surface
            : colorScheme.primary,
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
        padding: EdgeInsets.all(context.widthPercent(0.06)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: context.heightPercent(0.025)),
            Container(
              padding: EdgeInsets.all(context.widthPercent(0.05)),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/splash_screen_assets/ExamisAI.png",
                scale: context.isMobile ? 30 : 25,
              ),
            ),
            SizedBox(height: context.heightPercent(0.02)),
            Text(
              "Examis AI",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontSize: context.isMobile ? 28 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Version 1.0.0",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: context.isMobile ? 14 : 16,
              ),
            ),
            SizedBox(height: context.heightPercent(0.05)),
            Container(
              padding: EdgeInsets.all(context.widthPercent(0.05)),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Our Mission",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Lato',
                      fontSize: context.isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.015)),
                  Text(
                    "Examis AI is a Smart Assessment Portal designed to save educators hours of manual prep time. Crafted with a passion for clean UI/UX design and powerful Artificial Intelligence, this tool represents the future of automated curriculum management.",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'Lato',
                      fontSize: context.isMobile ? 14 : 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  Text(
                    "Whether you are generating MCQs, short answers, or complex essay prompts, our goal is to streamline your workflow so you can focus on what matters most: teaching.",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'Lato',
                      fontSize: context.isMobile ? 14 : 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.heightPercent(0.05)),
            Text(
              "Developed with Flutter & AI",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            Text(
              "© 2026 Examis AI",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
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