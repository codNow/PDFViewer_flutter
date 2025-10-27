import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DocumentCardWidget extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DocumentCardWidget({
    Key? key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final String fileName = document['name'] as String? ?? 'Unknown File';
  final String fileType = document['type'] as String? ?? 'unknown';
  final String fileSize = document['size'] as String? ?? '0 KB';
  final String modifiedDate =
      document['modifiedDate'] as String? ?? 'Unknown';
  final String thumbnailUrl = document['thumbnail'] as String? ?? '';


    return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              // Document thumbnail/icon
              Container(
                width: 14.w,
                height: 14.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _getFileTypeColor(context, fileType).withValues(alpha: 0.1),
                ),
                child: thumbnailUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomImageWidget(
                          imageUrl: thumbnailUrl,
                          width: 14.w,
                          height: 14.w,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: fileType.toLowerCase() == 'pdf'
                            ? Image.asset(
                                'assets/icons/pdf_icon.png', // Your custom PDF icon
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
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: _getFileTypeColor(context, fileType)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            modifiedDate,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          fileSize,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // More options indicator
              CustomIconWidget(
                iconName: 'more_vert',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
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
