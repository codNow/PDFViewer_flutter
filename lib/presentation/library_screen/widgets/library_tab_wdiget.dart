import 'package:flutter/material.dart';

class CustomSlidingSegment extends StatefulWidget {
  final List<SegmentTab> tabs;
  final int selectedIndex;
  final Function(int) onSelectionChanged;
  final Duration animationDuration;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double height;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool showShadow;

  const CustomSlidingSegment({
    Key? key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelectionChanged,
    this.animationDuration = const Duration(milliseconds: 300),
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
    this.borderColor,
    this.height = 48.0,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.showShadow = true,
  }) : super(key: key);

  @override
  State<CustomSlidingSegment> createState() => _CustomSlidingSegmentState();
}

class _CustomSlidingSegmentState extends State<CustomSlidingSegment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CustomSlidingSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _slideAnimation = Tween<double>(
        begin: _slideAnimation.value,
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = widget.selectedColor ?? theme.colorScheme.primary;
    final unselectedColor = widget.unselectedColor ?? theme.colorScheme.onSurface;
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.surface;
    final borderColor = widget.borderColor ?? theme.colorScheme.primary.withValues(alpha: 0.2);

    return Container(
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.fromLTRB(7, 5, 7, 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: widget.showShadow ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / widget.tabs.length;
          
          return Stack(
            children: [
              // Sliding background indicator
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: _slideAnimation.value * segmentWidth,
                    top: 0,
                    bottom: 0,
                    width: segmentWidth,
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(widget.borderRadius - 4),
                              boxShadow: widget.showShadow ? [
                                BoxShadow(
                                  color: selectedColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              // Tab content
              Row(
                children: widget.tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  final isSelected = index == widget.selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onSelectionChanged(index),
                      child: Container(
                        height: widget.height - 8,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon before title
                              if (tab.icon != null) ...[
                                AnimatedContainer(
                                  duration: widget.animationDuration,
                                  child: Icon(
                                    tab.icon,
                                    size: 18,
                                    color: isSelected ? Colors.white : unselectedColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              // Title text
                              AnimatedDefaultTextStyle(
                                duration: widget.animationDuration,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isSelected ? Colors.white : unselectedColor,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ) ?? TextStyle(
                                  color: isSelected ? Colors.white : unselectedColor,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                                child: Text(tab.title),
                              ),
                              // Count badge
                              if (tab.count > 0) ...[
                                const SizedBox(width: 6),
                                AnimatedContainer(
                                  duration: widget.animationDuration,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : theme.colorScheme.outline.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: widget.animationDuration,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isSelected ? Colors.white : unselectedColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ) ?? TextStyle(
                                      color: isSelected ? Colors.white : unselectedColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                    child: Text(tab.count.toString()),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SegmentTab {
  final String title;
  final int count;
  final IconData? icon; // Add icon property

  const SegmentTab({
    required this.title,
    this.count = 0,
    this.icon, // Optional icon parameter
  });
}