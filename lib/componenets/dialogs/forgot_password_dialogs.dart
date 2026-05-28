import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordFlow {
  static void showEmailPrompt(
    BuildContext context, {
    String initialEmail = "",
  }) {
    final TextEditingController resetEmailController = TextEditingController(
      text: initialEmail,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Reset Password",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter your email address and we will send you a 6-digit code to reset your password.",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            UniversalTextField(
              controller: resetEmailController,
              labelText: "Email Address",
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter your email address."),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final success = await context.read<AuthProvider>().resetPassword(
                context,
                email,
              );

              if (success && context.mounted) {
                _showOTPDialog(context, email);
              }
            },
            child: const Text(
              "Send Code",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showOTPDialog(BuildContext context, String email) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Enter Reset Code",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "We sent a 6-digit code to $email. Please enter it below to verify your identity.",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            UniversalTextField(
              controller: otpController,
              labelText: "6-Digit Code",
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.password, color: context.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = otpController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter the 6-digit code."),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final success = await context
                  .read<AuthProvider>()
                  .verifyRecoveryCode(context, email, code);

              if (success && context.mounted) {
                _showNewPasswordDialog(context);
              }
            },
            child: const Text(
              "Verify",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showNewPasswordDialog(BuildContext context) {
    final TextEditingController newPasswordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Create New Password",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UniversalTextField(
              controller: newPasswordController,
              labelText: "New Password",
              obscureText: true,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password must be at least 6 characters."),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              final authProvider = context.read<AuthProvider>();

              final success = await authProvider.updatePassword(
                context,
                newPassword,
              );

              if (success && context.mounted) {
                await authProvider.signOut(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Password updated! Please log in with your new password.",
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text(
              "Save & Log In",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lato',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
