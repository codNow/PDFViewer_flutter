import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AboutSectionWidget extends StatelessWidget {
  final String appVersion;
  final String storagePermissionStatus;
  final Function() onPrivacyPressed;
  final Function() onTermsPressed;

  const AboutSectionWidget({
    Key? key,
    required this.appVersion,
    required this.storagePermissionStatus,
    required this.onPrivacyPressed,
    required this.onTermsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                  iconName: 'info',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Theme.of(context).dividerColor,
            height: 1,
            indent: 4.w,
            endIndent: 4.w,
          ),
          _buildAppVersion(context),
          _buildStoragePermissions(context),
          _buildHelpOptions(context)
        ],
      ),
    );
  }

  Widget _buildAppVersion(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4), // Optional rounded corners
                child: Image.asset(
                  'assets/icons/pdf_icon.png', // Your app icon path
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Rest of your code remains the same
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDFViewer',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Version $appVersion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getSuccessColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Latest',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getSuccessColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStoragePermissions(BuildContext context) {
    final bool isGranted = storagePermissionStatus.toLowerCase() == 'granted';

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: (isGranted ? _getSuccessColor(context) : _getWarningColor(context))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: isGranted ? 'check_circle' : 'warning',
                color: isGranted ? _getSuccessColor(context) : _getWarningColor(context),
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
                  'Storage Permissions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Status: $storagePermissionStatus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isGranted
                        ? _getSuccessColor(context)
                        : _getWarningColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: () {
                // Handle permission request
              },
              child: Text(
                'Grant',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isGranted) ...[
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ]

        ],
      ),
    );
  }

  Widget _buildHelpOptions(BuildContext context) {
    return Column(
      children: [
        _buildHelpItem(
          context,
          'Privacy Policy',
          'Learn how we protect your data',
          'privacy_tip',
          onPrivacyPressed,
        ),
        _buildHelpItem(
          context,
          'Terms of Service',
          'Read our terms and conditions',
          'gavel',
          onTermsPressed,
        ),
      ],
    );
  }

  Widget _buildHelpItem(
    BuildContext context,
    String title,
    String subtitle,
    String iconName,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: iconName,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for theme-aware custom colors
  Color _getSuccessColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? AppTheme.successLight 
        : AppTheme.successDark;
  }

  Color _getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light 
        ? AppTheme.warningLight 
        : AppTheme.warningDark;
  }
}
