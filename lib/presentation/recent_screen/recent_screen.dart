import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfviewer/models/document_file.dart';
import 'package:pdfviewer/widgets/document_card_widget.dart';
import 'package:pdfviewer/services/storage_service.dart';
import 'package:pdfviewer/widgets/custom_icon_widget.dart';
import 'package:sizer/sizer.dart';
import 'package:share_plus/share_plus.dart';

class RecentScreen extends StatefulWidget {
  final String searchQuery;
  final List<String> activeFilters;
  final String currentSortOption;
  final Function(DocumentFile) onFileOpen;
  final VoidCallback onImportTap;
  final Function(int)? onRecentFilesCountChanged;
  const RecentScreen({
    Key? key,
    required this.searchQuery,
    required this.activeFilters,
    required this.currentSortOption,
    required this.onFileOpen,
    required this.onImportTap,
    this.onRecentFilesCountChanged,
  }) : super(key: key);

  State<RecentScreen> createState() => RecentScreenState();
}

class RecentScreenState extends State<RecentScreen> {
  List<DocumentFile> _recentFiles = [];
  bool _isLoading = false;
  Map<String, bool> _favorites = {};
  Map<String, bool> _bookmarks = {};
  Set<String> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
    _loadFavoritesAndBookmarks();
  }
  Future<void> refreshFiles() async {
    await _loadRecentFiles();
  }

  @override
  void didUpdateWidget(RecentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if search query changes
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.activeFilters != widget.activeFilters ||
        oldWidget.currentSortOption != widget.currentSortOption) {
      // No need to reload data, just trigger rebuild
      setState(() {});
    }
  }

  Future<void> _loadRecentFiles() async {
    setState(() => _isLoading = true);

    try {
      final recentFiles = await StorageService.getRecentFiles();
      setState(() {
        _recentFiles = recentFiles;
        _isLoading = false;
      });
      
      // Notify parent about count change
      widget.onRecentFilesCountChanged?.call(recentFiles.length);
    } catch (e) {
      setState(() => _isLoading = false);
      widget.onRecentFilesCountChanged?.call(0);
    }
  }


  Future<void> _loadFavoritesAndBookmarks() async {
    for (final file in _recentFiles) {
      _favorites[file.path] = await StorageService.isFavorite(file.path);
      _bookmarks[file.path] = await StorageService.isBookmarked(file.path);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleFavorite(DocumentFile documentFile) async {
    final isFavorite = _favorites[documentFile.path] ?? false;

    if (isFavorite) {
      await StorageService.removeFavorite(documentFile.path);
    } else {
      await StorageService.addFavorite(documentFile);
    }

    setState(() => _favorites[documentFile.path] = !isFavorite);
  }

  Future<void> _toggleBookmark(DocumentFile documentFile) async {
    final isBookmarked = _bookmarks[documentFile.path] ?? false;

    if (isBookmarked) {
      await StorageService.removeBookmark(documentFile.path);
    } else {
      await StorageService.addBookmark(documentFile);
    }

    setState(() => _bookmarks[documentFile.path] = !isBookmarked);
  }

  Future<void> _shareDocument(DocumentFile document) async {
    try {
      final file = File(document.path);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(document.path)],
          text: 'Check out this document: ${document.displayName}',
          subject: 'Shared Document: ${document.displayName}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: ${document.displayName}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRecentFile(DocumentFile document) async {
    await StorageService.deleteRecentFile(document.path);
    setState(() {
      _recentFiles.remove(document);
    });
  }

  List<DocumentFile> get _filteredFiles {
    List<DocumentFile> filtered = List.from(_recentFiles);

    // Apply search filter
    if (widget.searchQuery.isNotEmpty) {
      final lowercaseQuery = widget.searchQuery.toLowerCase();
      filtered = filtered.where((file) {
        return file.displayName.toLowerCase().contains(lowercaseQuery) ||
            file.name.toLowerCase().contains(lowercaseQuery) ||
            file.path.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    // Apply type filters
    if (widget.activeFilters.isNotEmpty) {
      filtered = filtered.where((doc) {
        final extension = _getFileExtension(doc.name);
        return widget.activeFilters.contains(extension);
      }).toList();
    }

    // Apply sorting
    switch (widget.currentSortOption) {
      case 'name':
        filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case 'date':
        filtered.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        break;
      case 'size':
        filtered.sort((a, b) => b.size.compareTo(a.size));
        break;
      case 'type':
        filtered.sort(
          (a, b) =>
              _getFileExtension(a.name).compareTo(_getFileExtension(b.name)),
        );
        break;
    }

    return filtered;
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  Map<String, dynamic> _documentFileToMap(DocumentFile document) {
    return {
      'id': document.id,
      'name': document.displayName,
      'type': _getFileExtension(document.name),
      'size': document.formattedSize,
      'modifiedDate': document.formattedDate,
      'thumbnail': '',
      'isOfflineAvailable': true,
      'lastOpened': document.lastOpened != null
          ? _formatLastOpened(document.lastOpened!)
          : null,
      'path': document.path,
    };
  }

  String _formatLastOpened(DateTime lastOpened) {
    final now = DateTime.now();
    final difference = now.difference(lastOpened);

    if (difference.inDays == 0) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes;

      if (hours > 0) {
        return 'Today, ${lastOpened.hour}:${lastOpened.minute.toString().padLeft(2, '0')}';
      } else if (minutes > 0) {
        return '$minutes minutes ago';
      } else {
        return 'Just now';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${lastOpened.hour}:${lastOpened.minute.toString().padLeft(2, '0')}';
    } else {
      return '${lastOpened.year.toString().padLeft(4, '0')}-${lastOpened.month.toString().padLeft(2, '0')}-${lastOpened.day.toString().padLeft(2, '0')} ${lastOpened.hour.toString().padLeft(2, '0')}:${lastOpened.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // Remove hardcoded background - let theme handle it
      appBar: AppBar(
        toolbarHeight: 0, // Makes it invisible
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            //_buildClearTab(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 2.h),
            Text(
              'Loading recent files...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final filteredDocuments = _filteredFiles;

    if (filteredDocuments.isEmpty && widget.searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'history',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'No recent documents',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Documents you open will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredDocuments.isEmpty && widget.searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'No recent documents found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecentFiles,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 1.w),
        itemCount: filteredDocuments.length,
        itemBuilder: (context, index) {
          final document = filteredDocuments[index];
          final isSelected = _selectedFiles.contains(document.path);

          return DocumentCardWidget(
            document: _documentFileToMap(document),
            isSelected: isSelected,
            onTap: () {
              widget.onFileOpen(document);
            },
            onLongPress: () => _showDocumentOptions(document),
            onOptionTap: () => _showQuickActions(document),
          );
        },
      ),
    );
  }

  void _showQuickActions(DocumentFile document) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFavorite = _favorites[document.path] ?? false;
    final isBookmarked = _bookmarks[document.path] ?? false;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(4.w, 4.w, 4.w, 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.open_in_new),
              title: Text('Open'),
              onTap: () => widget.onFileOpen(document),
            ),
            ListTile(
              leading: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : colorScheme.onSurface,
              ),
              title: Text(
                isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () async {
                Navigator.pop(context);
                await _toggleFavorite(document);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite
                          ? 'Removed from favorites'
                          : 'Added to favorites',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
              title: Text(isBookmarked ? 'Remove Bookmark' : 'Add Bookmark'),
              onTap: () async {
                Navigator.pop(context);
                await _toggleBookmark(document);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBookmarked ? 'Bookmark removed' : 'Added to bookmarks',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareDocument(document);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Remove from recent',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _deleteRecentFile(document);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('File deleted')));
              },
            ),
          ],
        ),
      ),
    );
  }
  void _showDocumentOptions(DocumentFile doc) {
    final isFavorite = _favorites[doc.path] ?? false;
    final isBookmarked = _bookmarks[doc.path] ?? false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 2.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          doc.path,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 3.h),
            _buildBottomSheetOption(context, Icons.share_rounded, 'Share', () {
              _shareDocument(doc);
            }),
            _buildBottomSheetOption(
              context,
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              () async {
                await _toggleFavorite(doc);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite ? 'Favorite removed' : 'Added to favorites',
                    ),
                  ),
                );
              },
            ),
            _buildBottomSheetOption(
              context,
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
              isBookmarked ? 'Remove from Bookmarks' : 'Add to Bookmarks',
              () async {
                await _toggleBookmark(doc);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBookmarked ? 'Bookmark removed' : 'Added to bookmarks',
                    ),
                  ),
                );
              },
            ),
            _buildBottomSheetOption(
              context,
              Icons.info_outline_rounded,
              'Details',
              () {
                // Implement details
              },
            ),
            _buildBottomSheetOption(
              context,
              Icons.delete_outline_rounded,
              'Remove from Recent',
              () async {
                Navigator.pop(context);
                final shouldDelete = await _showDeleteModal(doc);
                if (shouldDelete == true) {
                  await _deleteRecentFile(doc);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File removed from recent')),
                  );
                }
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteModal(DocumentFile document) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to remove this file?'),
              SizedBox(height: 8),
              Text(
                '${document.displayName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone. It will be remove from your history.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  Widget _buildBottomSheetOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.1)
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                size: 5.w,
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDestructive
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
