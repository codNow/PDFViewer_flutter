import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ResetOptionsWidget extends StatelessWidget {
  final Function() onClearSearchHistory;
  final Function() onResetPreferences;

  const ResetOptionsWidget({
    Key? key,
    required this.onClearSearchHistory,
    required this.onResetPreferences,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
    decoration: BoxDecoration(
      // Use theme card color
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'refresh',
                // Use theme error color
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Reset Options',
                // Use theme text styles with error color
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Divider(
          // Use theme divider color
          color: theme.dividerColor,
          height: 1,
          indent: 4.w,
          endIndent: 4.w,
        ),
        _buildResetOption(
          context,
          'Clear Search History',
          'Remove all search history data',
          'history',
          onClearSearchHistory,
          _getWarningColor(theme), // Use theme-aware warning color
        ),
        _buildResetOption(
          context,
          'Reset Preferences',
          'Reset all settings to default values',
          'settings_backup_restore',
          onResetPreferences,
          _getWarningColor(theme), // Use theme-aware warning color
        ),
      ],
    ),
  );
}

Widget _buildResetOption(
  BuildContext context,
  String title,
  String subtitle,
  String iconName,
  VoidCallback onTap,
  Color color,
) {
  final theme = Theme.of(context);
  
  return InkWell(
    onTap: () => _showConfirmationDialog(title, subtitle, onTap),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  // Use theme text styles with passed color
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  // Use theme text styles
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'chevron_right',
            color: color,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

// Helper method to get theme-aware warning color
Color _getWarningColor(ThemeData theme) {
  // Use tertiary color as warning equivalent, or define custom logic
  return theme.brightness == Brightness.light 
      ? AppTheme.warningLight 
      : AppTheme.warningDark;
}


  void _showConfirmationDialog(
      String title, String subtitle, VoidCallback onConfirm) {
    // This would typically show a confirmation dialog
    // For now, we'll just call the callback directly
    onConfirm();
  }
}
