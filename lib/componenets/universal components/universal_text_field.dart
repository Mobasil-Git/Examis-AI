import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';

class UniversalTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final int maxLines;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const UniversalTextField({
    super.key,
    required this.labelText,
    this.controller,
    this.hintText,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      obscureText: obscureText,
      style:  TextStyle(
        color: context.textPrimary,
        fontFamily: 'Lato',
        fontSize: 16,
      ),
      cursorColor: AppColors.primary, // Optional: uncomment if you want a blue cursor
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        labelText: labelText,
        hintText: hintText,
        labelStyle:  TextStyle(
          color: context.textSecondary,
          fontFamily: 'Lato',
        ),
        hintStyle: TextStyle(
          color: context.textSecondary.withAlpha(50),
          fontFamily: 'Lato',
        ),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: context.surface,

        // 1. Default State: Clean, subtle grey border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:  BorderSide(color: context.border, width: 1.5),
        ),

        // 2. Focused State: Highlights with your primary blue
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:  BorderSide(color: context.primary, width: 2),
        ),

        // 3. Error State: Turns red if validation fails
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:  BorderSide(color: context.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:  BorderSide(color: context.error, width: 2),
        ),

        isDense: true, // ADD THIS: Tells Flutter to make the field compact
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}