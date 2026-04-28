import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/componenets/widget/create_institute_form.dart';
import 'package:examis_ai/componenets/widget/profile_picture_widget.dart';
import 'package:examis_ai/pages/auth/login_page.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/provider/theme_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    final currentName = context.read<AuthProvider>().userName;
    nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Helper method for the Delete Confirmation Dialog
  void _showDeleteConfirmation(BuildContext context) {
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
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final success = await context.read<AuthProvider>().deleteAccount(
                context,
              );

              if (success && context.mounted) {
                // Wipe screen history and send to Login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                color: AppColors.error,
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
    final themeProvider = context.watch<ThemeProvider>();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? "No Email";
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode
            ? context.surface
            : AppColors.primary,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ProfilePictureWidget(
                userId: userId,
                // Optional: If you are already fetching the avatar URL in your
                // AuthProvider, pass it here! Otherwise, leave it null for now.
                initialAvatarUrl: authProvider.avatarUrl,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                userEmail,
                style: TextStyle(
                  color: context.textSecondary,
                  fontFamily: 'Lato',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 40),

            Text(
              "Full Name",
              style: TextStyle(
                color: context.textPrimary,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            UniversalTextField(
              controller: nameController,
              labelText: "Update Name",
              prefixIcon: Icon(
                Icons.badge_outlined,
                color: context.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "Change Password",
              style: TextStyle(
                color: context.textPrimary,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            UniversalTextField(
              controller: passwordController,
              labelText: "New Password (Leave blank to keep current)",
              obscureText: isPasswordHidden,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: context.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.textSecondary,
                ),
                onPressed: () =>
                    setState(() => isPasswordHidden = !isPasswordHidden),
              ),
            ),

            const SizedBox(height: 40),

            // --- SAVE CHANGES BUTTON ---
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

                final success = await context.read<AuthProvider>().updateProfile(
                  context,
                  newName: newName,
                  newPassword:
                      newPassword, // Pass the password (might be empty, which is fine)
                );

                if (success && context.mounted) {
                  // CHECK: Did they actually change their password?
                  if (newPassword.isNotEmpty) {
                    passwordController.clear();

                    // 1. Sign them out to kill the old session token!
                    await context.read<AuthProvider>().signOut(context);

                    if (!context.mounted) return;

                    // 2. Show a specific security message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Password changed successfully! Please log in again.",
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );

                    // 3. Kick them completely back to the Login Page, destroying the back-stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  } else {
                    // They ONLY updated their name. Just show a normal success message and stay on the page.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profile updated successfully!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),

            // ==========================================
            // NEW SECTION: INSTITUTE TEMPLATE UPLOAD
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Divider(color: context.border),
            ),

            Text(
              "Institute Templates",
              style: TextStyle(
                color: context.textPrimary,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Upload custom Word document headers for your generated exams.",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // The widget we built to handle the upload to Storage & Database
            CreateInstituteForm(
              onSuccess: () {
                // You can add logic here if you want to update the UI
                // after a successful upload, but the widget handles its own snackbar.
              },
            ),
            // ==========================================

            // --- DANGER ZONE ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Divider(color: context.border),
            ),

            const Text(
              "Danger Zone",
              style: TextStyle(
                color: AppColors.error,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Once you delete your account, there is no going back. All of your generated assessments and data will be permanently erased.",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // --- DELETE ACCOUNT BUTTON ---
            GestureDetector(
              onTap: () => _showDeleteConfirmation(context),
              // Triggers the safe dialog
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.error),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text(
                    "Delete Account",
                    style: TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32), // Extra padding at the bottom
          ],
        ),
      ),
    );
  }
}
