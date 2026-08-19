import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'universal_text_field.dart';
import '../../view_models/auth_view_model.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/utils.dart';
import '../../utils/responsive_ui.dart';

class ForgotPasswordFlow {
  static void showEmailPrompt(
      BuildContext context, {
        String initialEmail = "",
      }) {
    final TextEditingController resetEmailController = TextEditingController(
      text: initialEmail,
    );
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Reset Password",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter your email address and we will send you a 6-digit code to reset your password.",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: 13,
                height: 1.4,
              ),
            ),
            SizedBox(height: context.heightPercent(0.02)),
            UniversalTextField(
              controller: resetEmailController,
              labelText: "Email Address",
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: theme.colorScheme.onSurfaceVariant,
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
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                Utils.showSnackBar(context, "Please enter your email address.", AppColors.error);
                return;
              }

              Navigator.pop(ctx);

              final success = await context.read<AuthViewModel>().resetPassword(
                context,
                email,
              );

              if (success && context.mounted) {
                _showOTPDialog(context, email);
              }
            },
            child: Text(
              "Send Code",
              style: TextStyle(
                color: theme.colorScheme.primary,
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Enter Reset Code",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "We sent a 6-digit code to $email. Please enter it below to verify your identity.",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: 13,
                height: 1.4,
              ),
            ),
            SizedBox(height: context.heightPercent(0.02)),
            UniversalTextField(
              controller: otpController,
              labelText: "6-Digit Code",
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.password, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = otpController.text.trim();
              if (code.isEmpty) {
                Utils.showSnackBar(context, "Please enter the 6-digit code.", AppColors.error);
                return;
              }

              Navigator.pop(ctx);

              final success = await context
                  .read<AuthViewModel>()
                  .verifyRecoveryCode(context, email, code);

              if (success && context.mounted) {
                _showNewPasswordDialog(context);
              }
            },
            child: Text(
              "Verify",
              style: TextStyle(
                color: theme.colorScheme.primary,
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Create New Password",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              if (newPassword.length < 6) {
                Utils.showSnackBar(context, "Password must be at least 6 characters.", AppColors.error);
                return;
              }

              Navigator.pop(ctx);

              final authVM = context.read<AuthViewModel>();

              final success = await authVM.updatePassword(
                context,
                newPassword,
              );

              if (success && context.mounted) {
                await authVM.signOut(context);
                Utils.showSnackBar(context, "Password updated! Please log in with your new password.", AppColors.success);
              }
            },
            child: Text(
              "Save & Log In",
              style: TextStyle(
                color: theme.colorScheme.primary,
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