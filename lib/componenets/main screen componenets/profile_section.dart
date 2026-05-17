import 'package:examis_ai/componenets/widget/profile_picture_widget.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/provider/template_provider.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Container(
      height: context.heightPercent(0.22),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.surface : context.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              ProfilePictureWidget(
                userId: Supabase.instance.client.auth.currentUser!.id,
                initialAvatarUrl: authProvider.avatarUrl,
                radius: 22,
                showEditBadge: false,
              ),
              const Text(
                "Welcome!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                authProvider.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Consumer2<HistoryProvider, TemplateProvider>(
                  builder: (context, history, templateProvider, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          context,
                          title: "Exams",
                          value: history.totalAssessments.toString(),
                          icon: Icons.description_outlined,
                          iconColor: Colors.blueAccent,
                        ),

                        // 🚀 UPGRADED: Now uses AuthProvider for instant rendering
                        _buildStorageCard(context),

                        _buildStatCard(
                          context,
                          title: "Templates",
                          value: templateProvider.totalTemplates.toString(),
                          icon: Icons.bookmark_border_rounded,
                          iconColor: Colors.greenAccent,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color iconColor,
      }) {
    return Container(
      height: context.heightPercent(0.08),
      width: context.widthPercent(0.27),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.background : context.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: context.textSecondary,
              fontFamily: 'Lato',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 REWIRED LOGIC: Exact same UI, but pulls from local AuthProvider state
  Widget _buildStorageCard(BuildContext context) {
    // Watch the auth provider directly instead of using a StreamBuilder
    final authProvider = context.watch<AuthProvider>();

    double percentUsed = 0.0;
    Color barColor = Colors.greenAccent;

    // Do the MB math using the provider's local integers
    final usedMB = authProvider.storageUsedBytes / (1024 * 1024);
    final limitMB = authProvider.storageLimitBytes / (1024 * 1024);
    final remainingMB = limitMB - usedMB;

    if (authProvider.storageLimitBytes > 0) {
      percentUsed = (authProvider.storageUsedBytes / authProvider.storageLimitBytes).clamp(0.0, 1.0);
    }

    String displayValue = "${remainingMB.toStringAsFixed(1)} MB";

    // Dynamic bar colors
    if (percentUsed > 0.9) {
      barColor = Colors.redAccent;
    } else if (percentUsed > 0.7) {
      barColor = Colors.orangeAccent;
    }

    // Exact same UI structure you provided
    return Container(
      height: context.heightPercent(0.08),
      width: context.widthPercent(0.27),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.isDarkMode ? context.background : context.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayValue,
            style: TextStyle(
              color: context.textPrimary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentUsed,
              backgroundColor: context.isDarkMode ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Left",
            style: TextStyle(
              color: context.textSecondary,
              fontFamily: 'Lato',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}