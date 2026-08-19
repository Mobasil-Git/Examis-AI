import 'package:flutter/material.dart';
import '../../utils/responsive_ui.dart';

class SocialAuthButton extends StatelessWidget {
  final String text;
  final String imagePath;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.imagePath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        height: context.heightPercent(0.06), // Responsive button height
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(image: AssetImage(imagePath), height: context.heightPercent(0.025)),
            SizedBox(width: context.widthPercent(0.025)),
            Text(
              text,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontSize: context.isMobile ? 15 : 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}