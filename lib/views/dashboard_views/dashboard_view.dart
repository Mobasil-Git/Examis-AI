import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../resources/components/fade_scale_animation.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authVM = context.watch<AuthViewModel>();
    final historyVM = context.watch<HistoryViewModel>();
    final isDark = theme.brightness == Brightness.dark;

    int examsThisWeek = 0;
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      examsThisWeek = historyVM.savedAssessments.where((e) {
        if (e['created_at'] == null) return false;
        return DateTime.parse(e['created_at'].toString()).isAfter(oneWeekAgo);
      }).length;
    } catch (_) {}

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: () async {
          await context.read<AuthViewModel>().fetchUserProfile();
          await context.read<HistoryViewModel>().loadHistory();
        },
        child: Stack(
          children: [
            Container(
              height: context.heightPercent(0.4),
              width: double.infinity,
              color: colorScheme.primary,
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.widthPercent(0.06),
                        vertical: context.heightPercent(0.005),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.onPrimary.withAlpha(50),
                                backgroundImage: authVM.avatarUrl != null ? NetworkImage(authVM.avatarUrl!) : null,
                                child: authVM.avatarUrl == null
                                    ? Text(
                                  authVM.userName.isNotEmpty ? authVM.userName[0].toUpperCase() : 'U',
                                  style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                                )
                                    : null,
                              ),
                              SizedBox(width: context.widthPercent(0.03)),
                              Text(
                                "Examis AI",
                                style: TextStyle(color: colorScheme.onPrimary, fontFamily: 'Lato', fontWeight: FontWeight.w900, fontSize: context.isMobile ? 18 : 22),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.notifications_none_rounded, color: colorScheme.onPrimary),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06)),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authVM.userName.isNotEmpty ? authVM.userName : "Teacher",
                                  style: TextStyle(color: colorScheme.onPrimary, fontFamily: 'Lato', fontWeight: FontWeight.w900, fontSize: context.isMobile ? 24 : 32),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: context.heightPercent(0.005)),
                                Text(
                                  "Department of Computing Sciences",
                                  style: TextStyle(color: colorScheme.onPrimary.withAlpha(200), fontFamily: 'Lato', fontSize: context.isMobile ? 12 : 14),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: context.heightPercent(0.12),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                              child: Center(
                                child: Lottie.asset('assets/animations/lottie_animations/Ghostsmart.json', fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.04)),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: context.heightPercent(0.6)),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        context.widthPercent(0.06),
                        context.heightPercent(0.04),
                        context.widthPercent(0.06),
                        context.heightPercent(0.12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeScaleAnimation(
                            delay: 100,
                            child: Container(
                              padding: EdgeInsets.all(context.widthPercent(0.04)),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  _buildWideStatCard(
                                    context,
                                    title: "Exams generated",
                                    value: historyVM.totalAssessments.toString(),
                                    subText: "+$examsThisWeek this week",
                                    icon: Icons.description_outlined,
                                    bgColor: colorScheme.primaryContainer,
                                    textColor: colorScheme.onPrimaryContainer,
                                  ),
                                  SizedBox(height: context.heightPercent(0.015)),
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _buildSquareStatCard(
                                            context,
                                            title: "Templates",
                                            value: "24",
                                            icon: Icons.grid_view_rounded,
                                            bgColor: colorScheme.secondaryContainer,
                                            textColor: colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                        SizedBox(width: context.widthPercent(0.03)),
                                        Expanded(
                                          child: _buildSquareStatCard(
                                            context,
                                            title: "Daily usage",
                                            value: "${(authVM.storageUsedBytes / (1024 * 1024)).toStringAsFixed(0)} MB",
                                            icon: Icons.cloud_outlined,
                                            bgColor: colorScheme.tertiaryContainer,
                                            textColor: colorScheme.onTertiaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: context.heightPercent(0.02)),
                          FadeScaleAnimation(
                            delay: 400,
                            child: Text(
                              "Daily Insights",
                              style: TextStyle(color: colorScheme.onSurface, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: context.isMobile ? 16 : 18),
                            ),
                          ),
                          SizedBox(height: context.heightPercent(0.015)),
                          FadeScaleAnimation(
                            delay: 500,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(context.widthPercent(0.04)),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
                                    child: Icon(Icons.tips_and_updates_rounded, color: colorScheme.primary, size: 24),
                                  ),
                                  SizedBox(width: context.widthPercent(0.04)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Time Saved!", style: TextStyle(color: colorScheme.primary, fontFamily: 'Lato', fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text(
                                          "You have saved an estimated ${historyVM.hoursSaved} hours of manual typing this week.",
                                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontFamily: 'Lato', fontSize: 13, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideStatCard(BuildContext context, {required String title, required String value, required String subText, required IconData icon, required Color bgColor, required Color textColor}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.widthPercent(0.05)),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: TextStyle(color: textColor, fontFamily: 'Lato', fontSize: 14), overflow: TextOverflow.ellipsis)),
              Icon(icon, color: textColor, size: 20),
            ],
          ),
          SizedBox(height: context.heightPercent(0.015)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: textColor, fontFamily: 'Lato', fontWeight: FontWeight.w900, fontSize: context.isMobile ? 32 : 38),
            ),
          ),
          SizedBox(height: context.heightPercent(0.015)),
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: textColor, size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(subText, style: TextStyle(color: textColor, fontFamily: 'Lato', fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color bgColor, required Color textColor}) {
    return Container(
      padding: EdgeInsets.all(context.widthPercent(0.05)),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: textColor, size: 24),
          SizedBox(height: context.heightPercent(0.02)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(color: textColor, fontFamily: 'Lato', fontWeight: FontWeight.w900, fontSize: context.isMobile ? 26 : 32),
                ),
              ),
              SizedBox(height: context.heightPercent(0.005)),
              Text(
                title,
                style: TextStyle(color: textColor, fontFamily: 'Lato', fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}