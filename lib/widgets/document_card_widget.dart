import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentCardWidget extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onTap;
  final VoidCallback onOptionTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const DocumentCardWidget({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onOptionTap,
    required this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String fileName = document['name'] as String? ?? 'Unknown File';
    final String fileType = document['type'] as String? ?? 'unknown';
    final String fileSize = document['size'] as String? ?? '0 KB';
    final String modifiedDate =
        document['modifiedDate'] as String? ?? 'Unknown';
    final String thumbnailUrl = document['thumbnail'] as String? ?? '';
    final filePath = document['path'] as String? ?? '';
    final segments = filePath.split('/').where((s) => s.isNotEmpty).toList();
    final lastPath = segments.length > 1 
    ? '/${segments[segments.length - 2]}' 
    : '';
    final lastSecondPath = segments.length >= 2 
    ? '/${segments[segments.length - 2]}/${segments[segments.length - 1]}' 
    : segments.length == 1
        ? '/${segments[0]}'
        : '';
    if (segments.isNotEmpty) {
  segments.removeLast();
}

// Get the last two folder names
    final lastThirdPath = segments.length >= 2 
    ? '${segments[segments.length - 2]}/${segments[segments.length - 1]}' 
    : segments.length == 1
        ? segments[0]
        : '';


    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.fromLTRB(5.w, 1.w, 5.w, 1.w),
        padding: EdgeInsets.fromLTRB(2.w, 1.5.w, 2.w, 1.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                )
              : Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(
                        alpha: 0.3,
                      ),
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Document thumbnail/icon
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: _getFileTypeColor(
                      context,
                      fileType,
                    ).withValues(alpha: 0.1),
                  ),
                  child: thumbnailUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CustomImageWidget(
                            imageUrl: thumbnailUrl,
                            width: 12.w,
                            height: 12.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: fileType.toLowerCase() == 'pdf'
                              ? Image.asset(
                                  'assets/icons/logo.png',
                                  width: 6.w,
                                  height: 6.w,
                                  fit: BoxFit.contain,
                                )
                              : CustomIconWidget(
                                  iconName: _getFileTypeIcon(fileType),
                                  color: _getFileTypeColor(context, fileType),
                                  size: 6.w,
                                ),
                        ),
                ),
                SizedBox(width: 3.w),
            
                // File details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File name with overflow handling
                      Text(
                        fileName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
            
                      // File type and size
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'folder_open',
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 1.w),
                                  Flexible(
                                    child: Text(
                                      lastSecondPath,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            
                // More options or selection indicator
                GestureDetector(
                  onTap: isSelectionMode ? onTap : onOptionTap,
                  child: Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: isSelectionMode
                          ? Container(
                              key: ValueKey('selection'),
                              width: 6.w,
                              height: 6.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 4.w,
                                      color: Colors.white,
                                    )
                                  : null,
                            )
                          : CustomIconWidget(
                              key: ValueKey('more'),
                              iconName: 'more_vert',
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 4.w,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,                 
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 2.w), // Add this wrapper
                      child: CustomIconWidget(
                        iconName: 'storage',
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      fileSize,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'calendar_today',
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        modifiedDate,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }


  String _getFileTypeIcon(String fileType) {
    if (fileType.toLowerCase() == 'pdf') {
      return 'picture_as_pdf';
    }
    return 'insert_drive_file';
  }

  Color _getFileTypeColor(BuildContext context, fileType) {
    if (fileType.toLowerCase() == 'pdf') {
      return const Color(0xFF38BDF8);
    }
    return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
  }
}