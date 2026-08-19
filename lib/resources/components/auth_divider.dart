import 'package:flutter/material.dart';
import '../../utils/responsive_ui.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outline,
            thickness: 0.6,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.05)), // Responsive padding
          child: Text(
            'OR',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outline,
            thickness: 0.6,
          ),
        ),
      ],
    );
  }
}