import 'dart:ui';
import 'package:examis_ai/pages/dashboard_page.dart';
import 'package:examis_ai/pages/drawer_pages/history_page.dart';
import 'package:examis_ai/pages/drawer_pages/settings_page.dart';
import 'package:examis_ai/pages/drawer_pages/template_upload_page.dart';
import 'package:flutter/material.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:provider/provider.dart';

import '../pages/drawer_pages/edit_profile_page.dart';
import '../provider/auth_provider.dart';
import '../provider/history_provider.dart';

class MasterLayout extends StatefulWidget {
  const MasterLayout({super.key});

  @override
  State<MasterLayout> createState() => _MasterLayoutState();
}

class _MasterLayoutState extends State<MasterLayout> {
  int _currentIndex = 0;

  // The screens that will swap out when you tap the bottom tabs
  final List<Widget> _pages = [
    const DashboardPage(),
    // Swap with DashboardPage()
    const HistoryPage(),
    // Swap with HistoryPage()
    const TemplatesPage(),
    // Placeholder for templates
    const SettingsPage(),
    // Swap with SettingsPage()
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchUserProfile();
      context
          .read<HistoryProvider>()
          .loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      // We remove bottomNavigationBar entirely and use a Stack instead!
      body: Stack(
        children: [
          // 1. The Background Layer (Your Pages)
          IndexedStack(index: _currentIndex, children: _pages),

          // 2. The Foreground Layer (Your Floating Nav Bar)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              // SafeArea ensures it doesn't get hidden behind the iPhone Home Bar
              child: _buildGlassNavBar(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNavBar(BuildContext context) {
    // 1. Padding lifts it off the bottom of the screen so it "floats"
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      // Adjusted bottom padding
      child: ClipRRect(
        // ... rest of your code stays exactly the same
        borderRadius: BorderRadius.circular(30),

        // 2. BackdropFilter creates the Apple-style blurry glass effect behind the bar
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              // The surface color is highly transparent so the blur shows through
              color: context.surface.withAlpha(210),
              borderRadius: BorderRadius.circular(30),

              // 3. NO SHADOW! Just a crisp, subtle border to define the shape.
              border: Border.all(
                color: AppColors.primary.withAlpha(60),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.dashboard, "Dashboard"),
                _buildNavItem(1, Icons.history_rounded, "History"),
                _buildNavItem(2, Icons.upload_outlined, "Templates"),
                _buildNavItem(3, Icons.person_rounded, "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withAlpha(150),
              size: 24,
            ),
            // The text magically slides in and out when selected!
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    label,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppColors.primary,
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
