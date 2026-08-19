import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../resources/components/universal_text_field.dart';
import '../../resources/components/profile_picture_widget.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../utils/routes/route_names.dart';
import '../profile_views/edit_profile_view.dart';
import '../profile_views/about_us_view.dart';
import '../profile_views/feedback_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool notificationsEnabled = true;
  String institutionName = "Not Set";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      institutionName = prefs.getString('institutionName') ?? "Not Set";
    });
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Temporary files and cache cleared!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to clear cache."),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showInstitutionDialog() {
    final theme = Theme.of(context);
    final TextEditingController controller = TextEditingController(
      text: institutionName == "Not Set" ? "" : institutionName,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Institution Name",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: UniversalTextField(
          controller: controller,
          hintText: "School or University Name",
          prefixIcon: Icon(
            Icons.account_balance,
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => institutionName = newName);
                _saveStringSetting('institutionName', newName);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              "Save",
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeVM = context.watch<ThemeViewModel>();
    final authVM = context.watch<AuthViewModel>();

    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    final userEmail =
        Supabase.instance.client.auth.currentUser?.email ?? "No Email";
    final usedMB = authVM.storageUsedBytes / (1024 * 1024);

    double percentUsed = 0.0;
    if (authVM.storageLimitBytes > 0) {
      percentUsed = (authVM.storageUsedBytes / authVM.storageLimitBytes).clamp(
        0.0,
        1.0,
      );
    }
    String displayValue = usedMB.toStringAsFixed(1);

    final bool hasCustomKey = (authVM.customApiKey?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeVM.isDarkMode
            ? colorScheme.surface
            : colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile & Settings",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: context.widthPercent(0.06),
          vertical: context.heightPercent(0.03),
        ),
        children: [
          Container(
            padding: EdgeInsets.all(context.widthPercent(0.04)),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withAlpha(50)),
            ),
            child: Row(
              children: [
                ProfilePictureWidget(
                  userId: userId,
                  initialAvatarUrl: authVM.avatarUrl,
                  radius: context.isMobile ? 32 : 40,
                  showEditBadge: false,
                ),
                SizedBox(width: context.widthPercent(0.04)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authVM.userName.isEmpty
                            ? "Loading..."
                            : authVM.userName,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 18 : 20,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.005)),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'Lato',
                          fontSize: context.isMobile ? 13 : 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileView(),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary.withAlpha(20),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),

          _buildSectionHeader(context, "SUBSCRIPTION", colorScheme),

          Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(0.02)),
            child: Material(
              color: authVM.tier == 'premium'
                  ? Colors.amber.withAlpha(20)
                  : colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: authVM.tier == 'premium'
                      ? Colors.amber
                      : colorScheme.outline.withAlpha(50),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: ListTile(
                leading: Icon(
                  authVM.tier == 'premium'
                      ? Icons.workspace_premium
                      : Icons.stars_rounded,
                  color: authVM.tier == 'premium'
                      ? Colors.amber
                      : colorScheme.primary,
                  size: 32,
                ),
                title: Text(
                  authVM.tier == 'premium' ? "Premium Member" : "Free Tier",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  authVM.tier == 'premium'
                      ? "All features unlocked"
                      : "Tap to Upgrade to Premium",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: authVM.tier == 'free'
                    ? SizedBox(
                        height: 35,
                        width: 90,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            RouteNames.tierSelection,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            "Upgrade",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          if (authVM.tier == 'free') ...[
            _buildListTile(
              context,
              icon: Icons.key_rounded,
              title: "API Key Configuration",
              subtitle: hasCustomKey
                  ? "Custom Key Active"
                  : "Add key to unlock generation",
              iconColor: hasCustomKey ? Colors.green : Colors.orange,
              onTap: () =>
                  Navigator.pushNamed(context, RouteNames.byokSettings),
              colorScheme: colorScheme,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.heightPercent(0.01),
              ),
              child: Divider(
                color: colorScheme.outline.withAlpha(50),
                thickness: 1,
              ),
            ),
          ],

          Container(
            padding: EdgeInsets.all(context.widthPercent(0.05)),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(200),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_done_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: context.widthPercent(0.03)),
                    Text(
                      "Storage Quota",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 16 : 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.heightPercent(0.02)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentUsed,
                    backgroundColor: Colors.white.withAlpha(50),
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.015)),
                Text(
                  "$displayValue MB / 50 MB Used",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w500,
                    fontSize: context.isMobile ? 13 : 15,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.heightPercent(0.04)),

          _buildSectionHeader(context, "ASSESSMENT DEFAULTS", colorScheme),
          _buildListTile(
            context,
            icon: Icons.account_balance_outlined,
            title: "Institution Name",
            subtitle: institutionName,
            onTap: _showInstitutionDialog,
            colorScheme: colorScheme,
          ),

          _buildSectionHeader(context, "APP PREFERENCES", colorScheme),
          _buildSwitchTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: "Dark Mode",
            value: themeVM.isDarkMode,
            onChanged: (value) => themeVM.toggleTheme(value),
            colorScheme: colorScheme,
          ),
          _buildSwitchTile(
            context,
            icon: Icons.notifications_outlined,
            title: "Push Notifications",
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() => notificationsEnabled = value);
              _saveBoolSetting('notificationsEnabled', value);
            },
            colorScheme: colorScheme,
          ),

          _buildSectionHeader(context, "SUPPORT & ABOUT", colorScheme),
          _buildListTile(
            context,
            icon: Icons.rate_review_outlined,
            title: "Submit Feedback",
            subtitle: "Help us improve Examis AI",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackView()),
              );
            },
            colorScheme: colorScheme,
          ),
          _buildListTile(
            context,
            icon: Icons.info_outline_rounded,
            title: "About Us",
            subtitle: "Learn more about our mission",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsView()),
              );
            },
            colorScheme: colorScheme,
          ),

          _buildSectionHeader(context, "DATA & ACCOUNT", colorScheme),
          _buildListTile(
            context,
            icon: Icons.delete_outline,
            title: "Clear Local Cache",
            subtitle: "Free up space from uploaded documents",
            iconColor: colorScheme.error,
            titleColor: colorScheme.error,
            onTap: _clearCache,
            colorScheme: colorScheme,
          ),

          _buildListTile(
            context,
            icon: Icons.logout_rounded,
            title: "Log Out",
            iconColor: colorScheme.error,
            titleColor: colorScheme.error,
            hideTrailing: true,
            onTap: () async {
              await authVM.signOut(context);
              if (context.mounted)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
            },
            colorScheme: colorScheme,
          ),

          SizedBox(height: context.heightPercent(0.15)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.heightPercent(0.015),
        top: context.heightPercent(0.01),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontFamily: 'Lato',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool hideTrailing = false,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withAlpha(50)),
        ),
        clipBehavior: Clip.hardEdge,
        child: ListTile(
          leading: Icon(icon, color: iconColor ?? colorScheme.primary),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              color: titleColor ?? colorScheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                )
              : null,
          trailing: hideTrailing
              ? null
              : Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withAlpha(50)),
        ),
        clipBehavior: Clip.hardEdge,
        child: SwitchListTile(
          activeThumbColor: colorScheme.primary,
          activeTrackColor: colorScheme.primary.withAlpha(150),
          secondary: Icon(icon, color: colorScheme.primary),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
