import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/responsive_ui.dart';

class FeatureLockOverlay extends StatelessWidget {
  const FeatureLockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: colorScheme.surface.withAlpha(180),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_rounded, size: 80, color: colorScheme.primary),
              SizedBox(height: context.heightPercent(0.02)),
              Text(
                "Feature Locked",
                style: TextStyle(fontFamily: 'Lato', fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              SizedBox(height: context.heightPercent(0.01)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.1)),
                child: Text(
                  "You must either add your own Gemini API Key or upgrade to Premium to unlock assessment generation.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Lato', fontSize: 14, color: colorScheme.onSurfaceVariant),
                ),
              ),
              SizedBox(height: context.heightPercent(0.03)),
              Text(
                "Navigate to the Profile tab to setup.",
                style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w900, color: colorScheme.primary),
              )
            ],
          ),
        ),
      ),
    );
  }
}