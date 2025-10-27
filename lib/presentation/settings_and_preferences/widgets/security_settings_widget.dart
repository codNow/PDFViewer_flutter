import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SecuritySettingsWidget extends StatelessWidget {
  final bool biometricEnabled;
  final String autoLockTimer;
  final Function(bool) onBiometricChanged;
  final Function(String) onAutoLockChanged;

  const SecuritySettingsWidget({
    Key? key,
    required this.biometricEnabled,
    required this.autoLockTimer,
    required this.onBiometricChanged,
    required this.onAutoLockChanged,
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
                iconName: 'security',
                // Use theme primary color
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Security',
                // Use theme text styles
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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
        _buildBiometricToggle(context),
        _buildAutoLockTimer(context),
      ],
    ),
  );
}

Widget _buildBiometricToggle(BuildContext context) {
  final theme = Theme.of(context);
  
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            // Use theme primary color with alpha
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'fingerprint',
              // Use theme primary color
              color: theme.colorScheme.primary,
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
                'Biometric Authentication',
                // Use theme text styles
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Use Face ID, Touch ID, or Fingerprint to unlock',
                // Use theme text styles
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: biometricEnabled,
          onChanged: onBiometricChanged,
          // Remove hardcoded activeColor - let theme handle it
        ),
      ],
    ),
  );
}

Widget _buildAutoLockTimer(BuildContext context) {
  final theme = Theme.of(context);
  
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                // Use theme tertiary color (or warning equivalent) with alpha
                color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'timer',
                  // Use theme tertiary color (or warning equivalent)
                  color: theme.colorScheme.tertiary,
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
                    'Auto-lock Timer',
                    // Use theme text styles
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Current: $autoLockTimer',
                    // Use theme text styles
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            'Never',
            '1 minute',
            '5 minutes',
            '15 minutes',
            '30 minutes'
          ].map((timer) => _buildTimerOption(context, timer)).toList(),
        ),
      ],
    ),
  );
}

Widget _buildTimerOption(BuildContext context, String timer) {
  final theme = Theme.of(context);
  final bool isSelected = autoLockTimer == timer;

  return GestureDetector(
    onTap: () => onAutoLockChanged(timer),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isSelected
            // Use theme primary color with alpha for selected state
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            // Use theme surface color for unselected state
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              // Use theme primary color for selected border
              ? theme.colorScheme.primary
              // Use theme outline color for unselected border
              : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(
        timer,
        // Use theme text styles with conditional colors
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );
}


}
