import 'package:examis_ai/pages/auth/login_page.dart';
import 'package:examis_ai/pages/drawer_pages/about_us_page.dart';
import 'package:examis_ai/pages/drawer_pages/feedback_page.dart';
import 'package:examis_ai/pages/drawer_pages/history_page.dart';
import 'package:examis_ai/pages/drawer_pages/edit_profile_page.dart'; // ADD THIS
import 'package:examis_ai/pages/drawer_pages/settings_page.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ADD THIS

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider for the dynamic name
    final authProvider = context.watch<AuthProvider>();
    // Grab the email directly from the active session
    final String userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? "No Email";

    return Drawer(
      backgroundColor: context.background,
      child: Column(
        children: [
          // --- DYNAMIC PROFILE HEADER ---
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 24,
                right: 16,
              ),
              decoration:  BoxDecoration(
                color: context.isDarkMode ? context.surface : context.primary,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Row(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withAlpha(50),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name and Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Lato',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Lato',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // The navigation arrow
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- Menu Items ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.rate_review_outlined,
                  title: 'Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackPage()),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'About Us',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutUsPage()),
                    );
                  },
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Divider(color: context.border),
                ),

                // --- Logout Button ---
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Log Out',
                  isDestructive: true,
                    onTap: () async {
                      // 1. Instantly show a loading overlay that covers the whole screen
                      showDialog(
                        context: context,
                        barrierDismissible: false, // Prevents them from tapping outside to dismiss it
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );

                      try {
                        // 2. Talk to Supabase and sign out
                        await context.read<AuthProvider>().signOut(context); // Or however you call your sign out logic

                        // 3. Check if mounted before navigating!
                        if (!context.mounted) return;

                        // 4. Navigate to the Login Screen AND clear the routing history
                        // (This automatically destroys the loading dialog and the Dashboard)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()), // Replace with your actual Login Page class!
                              (route) => false,
                        );
                      } catch (e) {
                        // If it fails, pop the loading dialog off the screen so they aren't stuck
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Failed to log out. Please try again.")),
                          );
                        }
                      }
                    }
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              "Version 1.0.0",
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: 'Lato',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : context.textPrimary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color, size: 26),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontFamily: 'Lato',
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
