import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../resources/components/universal_text_field.dart';
import '../../view_models/auth_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../utils/routes/route_names.dart';

class BYOKSettingsView extends StatefulWidget {
  const BYOKSettingsView({super.key});

  @override
  State<BYOKSettingsView> createState() => _BYOKSettingsViewState();
}

class _BYOKSettingsViewState extends State<BYOKSettingsView> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _keyController.text = context.read<AuthViewModel>().customApiKey ?? '';
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _launchGeminiStudio() async {
    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "API Key Setup",
          style: TextStyle(fontFamily: 'Lato'),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.widthPercent(0.06)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.key_rounded, size: 50, color: colorScheme.primary),
            SizedBox(height: context.heightPercent(0.02)),
            Text(
              "Bring Your Own Key (BYOK)",
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: context.heightPercent(0.01)),
            Text(
              "To use the free tier, you must provide your own Gemini API key. Your key is stored securely on your local device and is never sent to our servers.",
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            SizedBox(height: context.heightPercent(0.04)),

            UniversalTextField(
              controller: _keyController,
              hintText: "Enter Gemini API Key (AIzaSy...)",
              prefixIcon: Icon(
                Icons.vpn_key_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: context.heightPercent(0.02)),
            GestureDetector(
              onTap: _launchGeminiStudio,
              child: Text(
                "Don't have a key? Get one free at Google AI Studio ↗",
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            SizedBox(height: context.heightPercent(0.06)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      RouteNames.home,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: colorScheme.outline.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      "Skip for Now",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                SizedBox(width: context.widthPercent(0.04)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_keyController.text.trim().isEmpty) return;
                      await context.read<AuthViewModel>().updateCustomApiKey(
                        _keyController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          RouteNames.home,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Save & Unlock",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
