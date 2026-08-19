import 'package:flutter/material.dart';
import '../../utils/responsive_ui.dart';

class BuildSocialIcon extends StatelessWidget {
  final String image;
  final String text;
  final VoidCallback onTap;

  const BuildSocialIcon({
    super.key,
    required this.image,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.heightPercent(0.055), // Made slightly taller for touch targets
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isDarkMode ? Colors.white38 : theme.colorScheme.outline.withAlpha(50),
            width: 1.5,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(image, height: context.heightPercent(0.03)),
            SizedBox(width: context.widthPercent(0.03)),
            Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: context.isMobile ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}