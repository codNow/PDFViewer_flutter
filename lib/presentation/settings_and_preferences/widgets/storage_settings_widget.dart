import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StorageSettingsWidget extends StatelessWidget {
  final double cacheUsage;
  final double totalStorage;
  final bool autoDownload;
  final Function() onClearCache;
  final Function(bool) onAutoDownloadChanged;

  const StorageSettingsWidget({
    Key? key,
    required this.cacheUsage,
    required this.totalStorage,
    required this.autoDownload,
    required this.onClearCache,
    required this.onAutoDownloadChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final double usagePercentage = totalStorage > 0 ? (cacheUsage / totalStorage) : 0;

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
    decoration: BoxDecoration(
      // Use theme card color instead of hardcoded
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
                iconName: 'storage',
                // Use theme primary color
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Storage',
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
        _buildCacheUsage(context, usagePercentage),
        _buildClearCacheButton(context),
        _buildAutoDownloadToggle(context),
      ],
    ),
  );
}

Widget _buildCacheUsage(BuildContext context, double usagePercentage) {
  final theme = Theme.of(context);
  
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cache Usage',
              // Use theme text styles
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_formatFileSize(cacheUsage)} / ${_formatFileSize(totalStorage)}',
              // Use theme text styles
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          height: 8,
          decoration: BoxDecoration(
            // Use theme outline color for background
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: usagePercentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _getUsageColor(context, usagePercentage),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          '${(usagePercentage * 100).toInt()}% used',
          // Use theme text styles
          style: theme.textTheme.bodySmall?.copyWith(
            color: _getUsageColor(context, usagePercentage),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildClearCacheButton(BuildContext context) {
  final theme = Theme.of(context);
  
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onClearCache,
        icon: CustomIconWidget(
          iconName: 'delete_sweep',
          // Use theme primary color
          color: theme.colorScheme.primary,
          size: 20,
        ),
        label: Text('Clear Cache'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
  );
}

Widget _buildAutoDownloadToggle(BuildContext context) {
  final theme = Theme.of(context);
  
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto-download cloud files',
                // Use theme text styles
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Automatically download files for offline viewing',
                // Use theme text styles
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: autoDownload,
          onChanged: onAutoDownloadChanged,
          // Remove hardcoded activeColor - let theme handle it
        ),
      ],
    ),
  );
}

// Helper method that now takes context to access theme
Color _getUsageColor(BuildContext context, double percentage) {
  final theme = Theme.of(context);
  
  if (percentage < 0.5) {
    return theme.colorScheme.primary; // Green-ish for low usage
  } else if (percentage < 0.8) {
    return Colors.orange; // Orange for medium usage
  } else {
    return theme.colorScheme.error; // Red for high usage
  }
}


  String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }


}
