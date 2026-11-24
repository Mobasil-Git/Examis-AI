import 'package:examisai/utils/theme/app_colors.dart';
import 'package:examisai/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../resources/components/universal_text_field.dart';
import '../../resources/components/profile_picture_widget.dart';
import '../../view_models/auth_provider.dart';
import '../../view_models/theme_provider.dart';
import '../../utils/responsive_ui.dart';
import '../../utils/routes/route_names.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  late TextEditingController nameController;
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;
  bool _hasInitializedName = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Delete Account?",
          style: TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action cannot be undone. All your data will be permanently lost.",
          style: TextStyle(fontFamily: 'Lato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(authProvider.notifier)
                  .deleteAccount(context);

              if (success && context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
              }
            },
            child: Text(
              "Delete",
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_hasInitializedName && authState.userName.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          nameController.text = authState.userName;
          _hasInitializedName = true;
        }
      });
    }

    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? "No Email";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeState.isDarkMode
            ? colorScheme.surface
            : colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Edit Profile",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProfilePictureWidget(
                userId: userId,
                initialAvatarUrl: authState.avatarUrl,
                radius: context.isMobile ? 50 : 60,
              ),
            ),
            SizedBox(height: context.heightPercent(0.02)),
            Center(
              child: Text(
                userEmail,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'Lato',
                  fontSize: context.isMobile ? 14 : 16,
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(0.05)),
            Text(
              "Full Name",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            UniversalTextField(
              controller: nameController,
              labelText: "Update Name",
              prefixIcon: Icon(
                Icons.badge_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: context.heightPercent(0.03)),
            Text(
              "Change Password",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            UniversalTextField(
              controller: passwordController,
              labelText: "New Password (Leave blank to keep current)",
              obscureText: isPasswordHidden,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.onSurfaceVariant,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () =>
                    setState(() => isPasswordHidden = !isPasswordHidden),
              ),
            ),
            SizedBox(height: context.heightPercent(0.025)),
            GestureDetector(
              onTap: () async {
                FocusScope.of(context).unfocus();
                final newName = nameController.text.trim();
                final newPassword = passwordController.text.trim();

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name cannot be empty.")),
                  );
                  return;
                }

                final success = await ref
                    .read(authProvider.notifier)
                    .updateProfile(
                      context,
                      newName: newName,
                      newPassword: newPassword,
                    );

                if (success && context.mounted) {
                  if (newPassword.isNotEmpty) {
                    passwordController.clear();
                    await ref.read(authProvider.notifier).signOut();

                    if (!context.mounted) return;
                    Utils.showSnackBar(
                      context,
                      'Password Successfully Changed, Please login again',
                      AppColors.success,
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                      (route) => false,
                    );
                  } else {
                    Utils.showSnackBar(
                      context,
                      'Profile Updated Successfully',
                      AppColors.success,
                    );
                  }
                }
              },
              child: Container(
                height: context.heightPercent(0.065),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: authState.isLoading
                      ? SizedBox(
                          height: context.widthPercent(0.06),
                          width: context.widthPercent(0.06),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.bold,
                            fontSize: context.isMobile ? 16 : 18,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(0.05)),
            Text(
              "Danger Zone",
              style: TextStyle(
                color: colorScheme.error,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: context.isMobile ? 18 : 20,
              ),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            Text(
              "Once you delete your account, there is no going back. All of your generated assessments and data will be permanently erased.",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'Lato',
                fontSize: context.isMobile ? 14 : 16,
              ),
            ),
            SizedBox(height: context.heightPercent(0.02)),
            GestureDetector(
              onTap: () => _showDeleteConfirmation(context, colorScheme),
              child: Container(
                height: context.heightPercent(0.065),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    "Delete Account",
                    style: TextStyle(
                      color: colorScheme.error,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 16 : 18,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: context.heightPercent(0.02)),
          ],
        ),
      ),
    );
  }
}
