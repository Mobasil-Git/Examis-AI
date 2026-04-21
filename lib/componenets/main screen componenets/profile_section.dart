import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:provider/provider.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Container(
      height: context.heightPercent(0.22),
      decoration:  BoxDecoration(
        color: context.isDarkMode ? context.surface : context.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(-8, 0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withAlpha(32),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
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
                child: Consumer<HistoryProvider>(
                    builder: (context, history, child) {
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
                          _buildStatCard(
                            context,
                            title: "Questions",
                            value: history.totalQuestionsGenerated.toString(),
                            icon: Icons.format_list_bulleted,
                            iconColor: Colors.orangeAccent,
                          ),
                          _buildStatCard(
                            context,
                            title: "Templates",
                            value: "0", // TODO: Wire this to our future TemplateProvider!
                            icon: Icons.bookmark_border_rounded, // A nice 'saved' icon
                            iconColor: Colors.greenAccent, // Distinct from blue and orange
                          ),
                        ],
                      );
                    }
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
        color: context.isDarkMode? context.background : context.surface,
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
}