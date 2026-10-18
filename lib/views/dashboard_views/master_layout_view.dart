import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../resources/components/feature_lock_overlay.dart';
import '../assessment_views/generation_wizard_view.dart';
import 'dashboard_view.dart';
import 'history_view.dart';
import 'template_view.dart';
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

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          if (!authVM.isAppUnlocked && _currentIndex != 3)
            const FeatureLockOverlay(),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: null,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GenerationWizardView(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: colorScheme.surface,
        elevation: 0,
        notchMargin: 8.0,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: context.heightPercent(0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavIcon(0, Icons.home_rounded, colorScheme),
                  _buildNavIcon(1, Icons.history_rounded, colorScheme),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavIcon(2, Icons.upload, colorScheme),
                  _buildNavIcon(3, Icons.person_rounded, colorScheme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(int index, IconData icon, ColorScheme colorScheme) {
    final isSelected = _currentIndex == index;
    return MaterialButton(
      minWidth: context.widthPercent(0.18),
      onPressed: () => _onNavTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected
                ? context.widthPercent(0.05)
                : context.widthPercent(0.03),
            vertical: context.heightPercent(0.008),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withAlpha(30)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20), // The pill shape
          ),
          child: Icon(
            icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant.withAlpha(150),
            size: isSelected ? 26 : 24,
          ),
        ),
      ),
    );
  }
}
