import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FileHandlingWidget extends StatelessWidget {
  final Map<String, String> defaultViewers;
  final double pdfConversionThreshold;
  final double offlineStorageLimit;
  final Function(String, String) onViewerChanged;
  final Function(double) onThresholdChanged;
  final Function(double) onStorageLimitChanged;

  const FileHandlingWidget({
    Key? key,
    required this.defaultViewers,
    required this.pdfConversionThreshold,
    required this.offlineStorageLimit,
    required this.onViewerChanged,
    required this.onThresholdChanged,
    required this.onStorageLimitChanged,
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
                iconName: 'folder_open',
                // Use theme primary color
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'File Handling',
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
        _buildDefaultViewers(context),
        _buildPdfConversionThreshold(context),
        _buildOfflineStorageLimit(context),
      ],
    ),
  );
}

Widget _buildDefaultViewers(BuildContext context) {
  final theme = Theme.of(context);
  
  return Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Viewers',
          // Use theme text styles
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        ...defaultViewers.entries.map((entry) {
          return _buildViewerOption(context, entry.key, entry.value);
        }).toList(),
      ],
    ),
  );
}

Widget _buildViewerOption(BuildContext context, String fileType, String currentViewer) {
  final theme = Theme.of(context);
  
  return Padding(
    padding: EdgeInsets.only(bottom: 2.h),
    child: Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: _getFileTypeColor(context, fileType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: _getFileTypeIcon(fileType),
              color: _getFileTypeColor(context, fileType),
              size: 20,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileType.toUpperCase(),
                // Use theme text styles
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Current: $currentViewer',
                // Use theme text styles
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (String viewer) => onViewerChanged(fileType, viewer),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'Native',
              child: Text('Native Viewer'),
            ),
            const PopupMenuItem(
              value: 'PDF',
              child: Text('PDF Converter'),
            ),
            const PopupMenuItem(
              value: 'Text',
              child: Text('Text Viewer'),
            ),
          ],
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              border: Border.all(
                // Use theme outline color
                color: theme.colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change',
                  // Use theme text styles
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'arrow_drop_down',
                  // Use theme color
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPdfConversionThreshold(BuildContext context) {
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
              'PDF Conversion Threshold',
              // Use theme text styles
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${pdfConversionThreshold.toInt()} MB',
              // Use theme text styles with primary color
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Convert large documents to PDF for better performance',
          // Use theme text styles
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        // Remove custom SliderTheme - let theme handle it
        Slider(
          value: pdfConversionThreshold,
          min: 5,
          max: 50,
          divisions: 9,
          onChanged: onThresholdChanged,
        ),
      ],
    ),
  );
}

Widget _buildOfflineStorageLimit(BuildContext context) {
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
              'Offline Storage Limit',
              // Use theme text styles
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${offlineStorageLimit.toInt()} GB',
              // Use theme text styles with primary color
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Maximum storage for offline documents',
          // Use theme text styles
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 2.h),
        // Remove custom SliderTheme - let theme handle it
        Slider(
          value: offlineStorageLimit,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: onStorageLimitChanged,
        ),
      ],
    ),
  );
}

// Updated helper method to use theme-aware colors
Color _getFileTypeColor(BuildContext context, String fileType) {
  final theme = Theme.of(context);
  
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return theme.colorScheme.error;
    case 'doc':
    case 'docx':
      return theme.colorScheme.primary;
    case 'xls':
    case 'xlsx':
      return theme.colorScheme.secondary;
    case 'ppt':
    case 'pptx':
      return theme.colorScheme.tertiary;
    default:
      return theme.colorScheme.outline;
  }
}

String _getFileTypeIcon(String fileType) {
  switch (fileType.toLowerCase()) {
    case 'pdf':
      return 'picture_as_pdf';
    case 'doc':
    case 'docx':
      return 'description';
    case 'xls':
    case 'xlsx':
      return 'table_chart';
    case 'ppt':
    case 'pptx':
      return 'slideshow';
    default:
      return 'insert_drive_file';
  }
}


}