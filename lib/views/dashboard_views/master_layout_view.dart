import 'dart:ui';
import 'package:examisai/views/dashboard_views/template_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../resources/components/feature_lock_overlay.dart';
import 'dashboard_view.dart';
import 'history_view.dart';
import 'settings_view.dart';

class MasterLayoutView extends StatefulWidget {
  const MasterLayoutView({super.key});

  @override
  State<MasterLayoutView> createState() => _MasterLayoutViewState();
}

class _MasterLayoutViewState extends State<MasterLayoutView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const HistoryView(),
    const TemplatesView(),
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().fetchUserProfile();
      context.read<HistoryViewModel>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),

          if (!authVM.isAppUnlocked && _currentIndex != 3)
            const FeatureLockOverlay(),

          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: _buildGlassNavBar(context, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNavBar(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
          left: context.widthPercent(0.06),
          right: context.widthPercent(0.06),
          bottom: context.heightPercent(0.02)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: context.heightPercent(0.08),
            padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.02)),
            decoration: BoxDecoration(
              color: colorScheme.surface.withAlpha(210),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorScheme.primary.withAlpha(60),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.dashboard, "Dashboard", colorScheme),
                _buildNavItem(1, Icons.history_rounded, "History", colorScheme),
                _buildNavItem(2, Icons.upload_outlined, "Templates", colorScheme),
                _buildNavItem(3, Icons.person_rounded, "Profile", colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ColorScheme colorScheme) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        padding: EdgeInsets.symmetric(
            horizontal: context.widthPercent(0.04),
            vertical: context.heightPercent(0.01)
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withAlpha(150),
              size: 24,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: Padding(
                  padding: EdgeInsets.only(left: context.widthPercent(0.015)),
                  child: Text(
                    label,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}