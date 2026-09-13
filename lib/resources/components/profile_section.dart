import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_picture_widget.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../view_models/template_view_model.dart';
import '../../utils/responsive_ui.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? theme.colorScheme.surface : theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: context.widthPercent(0.05),
            right: context.widthPercent(0.05),
            top: context.heightPercent(0.015),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfilePictureWidget(
                userId: userId,
                initialAvatarUrl: authVM.avatarUrl,
                radius: context.isMobile ? 22 : 28,
                showEditBadge: false,
              ),
              SizedBox(height: context.heightPercent(0.01)),
              Text(
                "Welcome!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.isMobile ? 14 : 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                authVM.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w700,
                  fontSize: context.isMobile ? 24 : 28,
                ),
              ),
              SizedBox(height: context.heightPercent(0.025)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.02)),
                child: Consumer2<HistoryViewModel, TemplateViewModel>(
                  builder: (context, historyVM, templateVM, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          context,
                          title: "Exams",
                          value: historyVM.totalAssessments.toString(),
                          icon: Icons.description_outlined,
                          iconColor: Colors.blueAccent,
                          theme: theme,
                          isDarkMode: isDarkMode,
                        ),
                        _buildStorageCard(context, authVM, theme, isDarkMode),
                        _buildStatCard(
                          context,
                          title: "Templates",
                          value: templateVM.totalTemplates.toString(),
                          icon: Icons.bookmark_border_rounded,
                          iconColor: Colors.greenAccent,
                          theme: theme,
                          isDarkMode: isDarkMode,
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
        required ThemeData theme,
        required bool isDarkMode,
      }) {
    return Container(
      height: context.heightPercent(0.08),
      width: context.widthPercent(0.27),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.scaffoldBackgroundColor : theme.colorScheme.surface,
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
              SizedBox(width: context.widthPercent(0.01)),
              Text(
                value,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(0.005)),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, AuthViewModel authVM, ThemeData theme, bool isDarkMode) {
    double percentUsed = 0.0;
    Color barColor = Colors.greenAccent;

    final usedMB = authVM.storageUsedBytes / (1024 * 1024);
    final limitMB = authVM.storageLimitBytes / (1024 * 1024);
    final remainingMB = limitMB - usedMB;

    if (authVM.storageLimitBytes > 0) {
      percentUsed = (authVM.storageUsedBytes / authVM.storageLimitBytes).clamp(0.0, 1.0);
    }

    String displayValue = "${remainingMB.toStringAsFixed(1)} MB";

    if (percentUsed > 0.9) {
      barColor = Colors.redAccent;
    } else if (percentUsed > 0.7) {
      barColor = Colors.orangeAccent;
    }

    return Container(
      height: context.heightPercent(0.08),
      width: context.widthPercent(0.27),
      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.03)),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.scaffoldBackgroundColor : theme.colorScheme.surface,
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
              color: theme.colorScheme.onSurface,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: context.heightPercent(0.005)),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentUsed,
              backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.005)),
          Text(
            "Left",
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
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