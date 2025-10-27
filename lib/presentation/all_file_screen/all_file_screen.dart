import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfviewer/core/app_export.dart';
import 'package:pdfviewer/models/document_file.dart';
import 'package:pdfviewer/presentation/dashboard_screen/widgets/asset_icon_widget.dart';
import 'package:pdfviewer/widgets/document_card_widget.dart';
import 'package:pdfviewer/presentation/all_file_screen/widgets/empty_state_widget.dart';
import 'package:pdfviewer/services/pdf_service.dart';
import 'package:pdfviewer/services/storage_service.dart';
import 'package:sizer/sizer.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class AllFileScreen extends StatefulWidget {
  final String searchQuery;
  final List<String> activeFilters;
  final String currentSortOption;
  final Function(DocumentFile) onFileOpen;
  final VoidCallback onImportTap;
  final Function(bool) onSelectionModeChanged;

  const AllFileScreen({
    Key? key,
    required this.searchQuery,
    required this.activeFilters,
    required this.currentSortOption,
    required this.onFileOpen,
    required this.onImportTap,
    required this.onSelectionModeChanged,
  }) : super(key: key);

  @override
  State<AllFileScreen> createState() => _AllFileScreenState();
}

class _AllFileScreenState extends State<AllFileScreen> {
  List<DocumentFile> _allFiles = [];
  List<DocumentFile> _filteredFiles = [];
  bool _isLoading = false;
  bool _hasPermission = true;

  // Track favorites and bookmarks for each file
  Map<String, bool> _favorites = {};
  Map<String, bool> _bookmarks = {};

  // Multi-select state
  bool _isSelectionMode = false;
  Set<String> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _loadAllFiles();
  }

  @override
  void didUpdateWidget(AllFileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.activeFilters != widget.activeFilters ||
        oldWidget.currentSortOption != widget.currentSortOption) {
      _applyFiltersAndSort();
    }
  }

  void _selectAll() {
    setState(() {
      _selectedFiles = _filteredFiles.map((f) => f.path).toSet();
    });
    HapticFeedback.lightImpact();
  }

  void _enterSelectionMode(DocumentFile file) {
    setState(() {
      _isSelectionMode = true;
      _selectedFiles.add(file.path);
    });
    HapticFeedback.mediumImpact();

    // ← ADD THESE TWO LINES
    debugPrint('AllFileScreen: Entering selection mode'); // Debug log
    widget.onSelectionModeChanged.call(true); // Notify parent
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });

    // ← ADD THESE TWO LINES
    debugPrint('AllFileScreen: Exiting selection mode'); // Debug log
    widget.onSelectionModeChanged.call(false); // Notify parent
  }

  void _toggleFileSelection(DocumentFile file) {
    setState(() {
      if (_selectedFiles.contains(file.path)) {
        _selectedFiles.remove(file.path);
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
          // ← ADD THESE TWO LINES
          debugPrint(
            'AllFileScreen: Auto-exiting selection mode (no files selected)',
          );
          widget.onSelectionModeChanged?.call(false); // Notify parent
        }
      } else {
        _selectedFiles.add(file.path);
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _deleteSelectedFiles() async {
    // Store the count before showing dialog
    final count = _selectedFiles.length;

    final shouldDelete = await _showBulkDeleteModal(count);
    if (shouldDelete != true) return;

    int successCount = 0;
    int failCount = 0;

    // Create a copy of selected files to avoid modification during iteration
    final filesToDelete = List<String>.from(_selectedFiles);

    for (final path in filesToDelete) {
      try {
        final doc = _allFiles.firstWhere((f) => f.path == path);
        final success = await StorageService.deleteDocumentFile(doc);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        debugPrint('Error deleting file at $path: $e');
        failCount++;
      }
    }

    // Update state
    setState(() {
      _allFiles.removeWhere((f) => filesToDelete.contains(f.path));
      _filteredFiles.removeWhere((f) => filesToDelete.contains(f.path));
      _isSelectionMode = false;
      _selectedFiles.clear();
    });

    // Notify parent after deletion
    widget.onSelectionModeChanged.call(false);

    // Show result message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount file(s) deleted successfully${failCount > 0 ? ', $failCount failed' : ''}',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.lightBlueAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Refresh file list
    StorageService.refreshAllPdfFiles();
  }

  Future<bool?> _showBulkDeleteModal(int count) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        // Use different context name
        return AlertDialog(
          title: Text('Delete Files'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete $count file(s)?'),
              SizedBox(height: 8),
              Text(
                'This action cannot be undone. Files will be deleted from your device storage.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareSelectedFiles() async {
    try {
      // Create list of files to share
      final filesToShare = _allFiles
          .where((f) => _selectedFiles.contains(f.path))
          .map((f) => XFile(f.path))
          .toList();

      if (filesToShare.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No files selected to share'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Share the files
      await Share.shareXFiles(
        filesToShare,
        text: 'Sharing ${filesToShare.length} document(s)',
      );

      // Exit selection mode after sharing
      setState(() {
        _isSelectionMode = false;
        _selectedFiles.clear();
      });

      widget.onSelectionModeChanged?.call(false);
    } catch (e) {
      debugPrint('Error sharing files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing files: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadAllFiles({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    try {
      final files = forceRefresh
          ? await FileService.getFreshFiles()
          : await FileService.scanForFiles();

      debugPrint('FilesTab: Loaded ${files.length} files');

      setState(() {
        _allFiles = files;
        _isLoading = false;
      });

      await _loadFavoritesAndBookmarks();
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Error loading files in FilesTab: $e');
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
    }
  }

  Future<void> _loadFavoritesAndBookmarks() async {
    for (final file in _allFiles) {
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

  void _applyFiltersAndSort() {
    List<DocumentFile> filtered = List.from(_allFiles);

    if (widget.searchQuery.isNotEmpty) {
      final lowercaseQuery = widget.searchQuery.toLowerCase();
      filtered = filtered.where((file) {
        return file.displayName.toLowerCase().contains(lowercaseQuery) ||
            file.name.toLowerCase().contains(lowercaseQuery) ||
            file.path.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    if (widget.activeFilters.isNotEmpty) {
      filtered = filtered.where((doc) {
        final extension = _getFileExtension(doc.name);
        return widget.activeFilters.contains(extension);
      }).toList();
    }

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

    setState(() {
      _filteredFiles = filtered;
    });
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  void _openFile(DocumentFile documentFile) async {
    await StorageService.addRecentFile(documentFile);
    widget.onFileOpen(documentFile);
  }

  void _showDocumentOptions(DocumentFile doc) {
    final isFavorite = _favorites[doc.path] ?? false;
    final isBookmarked = _bookmarks[doc.path] ?? false;
    final filePath = doc.path as String? ?? '';
    final segments = filePath.split('/').where((s) => s.isNotEmpty).toList();
    final lastSecondPath = segments.length >= 2 
    ? '/${segments[segments.length - 2]}/${segments[segments.length - 1]}' 
    : segments.length == 1
        ? '/${segments[0]}'
        : '';
    if (segments.isNotEmpty) {
      segments.removeLast();
    }
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
          bottom: MediaQuery.of(context).viewInsets.bottom + 7.h,
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
                    child: AssetIconWidget(
                      iconName: 'logo',
                      size: 5.w,
                      fileExtension: 'png',
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
                          lastSecondPath,
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
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_add_outlined,
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
            GestureDetector(
              onTap: () async{
                Navigator.pop(context);
                final shouldDelete = await _showDeleteModal(doc);
                if (shouldDelete == true) {
                  final success = await StorageService.deleteDocumentFile(doc);
                  if (success) {
                    setState(() {
                      _filteredFiles.removeWhere(
                        (file) => file.path == doc.path,
                      );
                      _allFiles.removeWhere((file) => file.path == doc.path);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'File "${doc.displayName}" deleted successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    StorageService.refreshAllPdfFiles();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete file or file not found',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Delete File',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
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

  Future<bool?> _showDeleteModal(DocumentFile document) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this file?'),
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
                'This action cannot be undone. It will be deleted from your device storage.',
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
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 2.h),
            Text(
              'Loading files...',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'folder_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Storage Permission Required',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please grant storage permission to access your documents',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () => _loadAllFiles(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredFiles.isEmpty &&
        widget.searchQuery.isEmpty &&
        widget.activeFilters.isEmpty) {
      return EmptyStateWidget(onImportTap: widget.onImportTap);
    }

    if (_filteredFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'No documents found',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search or filters',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: RefreshIndicator(
          onRefresh: () => _loadAllFiles(forceRefresh: true),
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(0, 0.5.h, 0, 10.h),
            itemCount: _filteredFiles.length,
            itemBuilder: (context, index) {
              final document = _filteredFiles[index];
              final isSelected = _selectedFiles.contains(document.path);

              return InkWell(
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleFileSelection(document);
                  } else {
                    _openFile(document);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _enterSelectionMode(document);
                  }
                },
                child: DocumentCardWidget(
                  document: _documentFileToMap(document),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleFileSelection(document);
                    } else {
                      _openFile(document);
                    }
                  },
                  onOptionTap: () => _showDocumentOptions(document),
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _enterSelectionMode(document);
                    }
                  },
                  isSelected: isSelected,
                  isSelectionMode: _isSelectionMode,
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _isSelectionMode
            ? Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: _exitSelectionMode,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${_selectedFiles.length} selected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Spacer(),
                      if (_selectedFiles.length < _filteredFiles.length)
                        IconButton(
                          icon: Icon(Icons.select_all),
                          onPressed: _selectAll,
                          tooltip: 'Select All',
                        ),
                      SizedBox(width: 2.w),
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: _selectedFiles.isNotEmpty
                            ? () async {
                                await _shareSelectedFiles();
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: _selectedFiles.isNotEmpty
                            ? () async {
                                await _deleteSelectedFiles();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
