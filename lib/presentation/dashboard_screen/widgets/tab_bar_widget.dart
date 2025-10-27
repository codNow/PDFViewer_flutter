import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TabBarWidget extends StatelessWidget {
  final TabController tabController;
  final List<String> tabLabels;
  
  const TabBarWidget({
    Key? key,
    required this.tabController,
    required this.tabLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(bottom: 1.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        tabs: tabLabels
            .map(
              (label) => Tab(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.5.w,
                    vertical: 2.w,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 3,
          ),
          insets: EdgeInsets.symmetric(horizontal: 6.w),
          borderRadius: BorderRadius.circular(2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(1.w),
        // Use labelStyle and unselectedLabelStyle for complete control
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: theme.colorScheme.primary, // Set color here
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant, // Set color here
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
