import 'dart:io';
import 'package:examis_ai/componenets/universal%20components/universal_text_field.dart';
import 'package:examis_ai/provider/theme_provider.dart'; // ADDED THIS
import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ADDED THIS
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  String selectedDifficulty = "Medium";
  String institutionName = "Not Set";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- Load Settings ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      selectedDifficulty = prefs.getString('selectedDifficulty') ?? "Medium";
      institutionName = prefs.getString('institutionName') ?? "Not Set";
      // Note: We no longer need to manually load isDarkMode here because
      // the ThemeProvider handles it automatically!
    });
  }

  // --- Save Settings ---
  Future<void> _saveBoolSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // --- Institution Name Dialog ---
  void _showInstitutionDialog() {
    final TextEditingController controller = TextEditingController(
      text: institutionName == "Not Set" ? "" : institutionName,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface, // Uses dynamic surface!
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Institution Name",
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: UniversalTextField(
          controller: controller,
          labelText: "School or University Name",
          prefixIcon: Icon(
            Icons.account_balance,
            color: context.textSecondary,
          ),
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
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => institutionName = newName);
                _saveStringSetting('institutionName', newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              "Save",
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

  // --- Real Cache Clearing Logic ---
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
            backgroundColor: AppColors.success, // Use standard success color
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to clear cache."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH THE THEME PROVIDER TO GET CURRENT STATUS
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        // Dynamic AppBar background to look good in dark mode!
        backgroundColor: themeProvider.isDarkMode ? context.surface : AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lato',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _buildSectionHeader("ASSESSMENT DEFAULTS"),

          _buildListTile(
            icon: Icons.account_balance_outlined,
            title: "Institution Name",
            subtitle: institutionName,
            onTap: _showInstitutionDialog,
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: const Icon(Icons.speed, color: AppColors.primary),
            title: Text(
              "Default Difficulty",
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            subtitle: Text(
              selectedDifficulty,
              style: TextStyle(
                fontFamily: 'Lato',
                color: context.textSecondary,
              ),
            ),
            trailing: DropdownButton<String>(
              value: selectedDifficulty,
              dropdownColor: context.surface, // Drops down in correct color!
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: context.textSecondary,
              ),
              items: ["Easy", "Medium", "Hard"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(fontFamily: 'Lato', color: context.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => selectedDifficulty = newValue);
                  _saveStringSetting('selectedDifficulty', newValue);
                }
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.border, thickness: 1),
          ),

          _buildSectionHeader("APP PREFERENCES"),

          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            activeThumbColor: AppColors.primary,
            secondary: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              "Push Notifications",
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            subtitle: Text(
              "Get notified when generation completes",
              style: TextStyle(
                fontFamily: 'Lato',
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() => notificationsEnabled = value);
              _saveBoolSetting('notificationsEnabled', value);
            },
          ),

          // --- WIRED UP DARK MODE SWITCH ---
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            activeThumbColor: AppColors.primary,
            secondary: const Icon(
              Icons.dark_mode_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              "Dark Mode",
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            value: themeProvider.isDarkMode, // Reads live state from provider!
            onChanged: (value) {
              // Tells the whole app to rebuild with the new theme!
              themeProvider.toggleTheme(value);
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.border, thickness: 1),
          ),

          _buildSectionHeader("DATA & STORAGE"),

          _buildListTile(
            icon: Icons.delete_outline,
            title: "Clear Local Cache",
            subtitle: "Free up space from uploaded documents",
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.textSecondary,
          fontFamily: 'Lato',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // FIXED METHOD! Made colors nullable and assigned context fallback inside the body.
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,  // Nullable
    Color? titleColor, // Nullable
  }) {
    // Check if null, if so, use context colors!
    final finalIconColor = iconColor ?? context.primary;
    final finalTitleColor = titleColor ?? context.textPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: finalIconColor),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Lato',
          fontWeight: FontWeight.w600,
          color: finalTitleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Lato',
          color: context.textSecondary,
          fontSize: 13,
        ),
      )
          : null,
      trailing: Icon(Icons.chevron_right, color: context.textSecondary),
      onTap: onTap,
    );
  }
}