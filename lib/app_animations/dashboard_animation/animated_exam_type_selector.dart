import 'package:examis_ai/theming/app_colors.dart';
import 'package:flutter/material.dart';

class AnimatedExamTypeSelector extends StatefulWidget {
  final Function(String) onTypeSelected;
  final bool hasPractical; // 🚀 NEW: Tells the UI if practical is allowed

  const AnimatedExamTypeSelector({
    super.key,
    required this.onTypeSelected,
    this.hasPractical = true,
  });

  @override
  State<AnimatedExamTypeSelector> createState() =>
      _AnimatedExamTypeSelectorState();
}

class _AnimatedExamTypeSelectorState extends State<AnimatedExamTypeSelector> {
  int _selectedIndex = 0;
  late List<String> _examTypes;

  @override
  void initState() {
    super.initState();
    _buildExamTypes();
  }

  // 🚀 React to changes if a teacher imports a new course
  @override
  void didUpdateWidget(AnimatedExamTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasPractical != widget.hasPractical) {
      setState(() {
        _buildExamTypes();
      });
    }
  }

  void _buildExamTypes() {
    _examTypes = ['Mid-Term', 'Final'];
    if (widget.hasPractical) {
      _examTypes.add('Practical');
    }
    // Prevent out-of-bounds error if Practical was selected but is now gone
    if (_selectedIndex >= _examTypes.length) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(30),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _examTypes.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  width: itemWidth,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              Row(
                children: List.generate(_examTypes.length, (index) {
                  final isSelected = _selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        widget.onTypeSelected(_examTypes[index]);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          child: Text(_examTypes[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}