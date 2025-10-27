import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onImportTap;

  const EmptyStateWidget({
    Key? key,
    required this.onImportTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration placeholder
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'folder_open',
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),

            // Title
            Text(
              'No PDF Documents Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),

            // Description
            Text(
              'Start by importing your first PDF document from your device or cloud storage.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),

            // Import button
            ElevatedButton.icon(
              onPressed: onImportTap,
              icon: CustomIconWidget(
                iconName: 'add',
                color: Theme.of(context).colorScheme.onPrimary,
                size: 5.w,
              ),
              label: Text(
                'Import Your First PDF',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
