import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.heightPercent(0.05),
        // REMOVED double.infinity!
        decoration: BoxDecoration(
          color: context.background, // Safer color referencing
          borderRadius: BorderRadius.circular(25),
          // Fallback to a grey border if context.border extension isn't found
          border: Border.all(color: context.isDarkMode? Colors.black38:Colors.grey.shade300, width: 1.5),
        ),
        // Adding Padding to give the text and logo room to breathe
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max, // Forces Row to expand safely
          children: [
            Image.asset(image, height: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: context.isDarkMode? Colors.white : Colors.black,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}