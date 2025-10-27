import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfviewer/presentation/library_screen/widgets/library_tab_wdiget.dart';
import 'package:pdfviewer/widgets/document_card_widget.dart';
import 'package:pdfviewer/services/storage_service.dart'; // Add this import
import 'package:pdfviewer/models/document_file.dart'; // Add this import
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';


class LibraryScreen extends StatefulWidget {
  final Function(DocumentFile) onFileOpen;
  final VoidCallback onImportTap;
  final Function(int)? onLibrarySubTabChanged;
  final Function(int, int)? onLibraryCountsChanged;

  const LibraryScreen({
    Key? key,
    required this.onFileOpen,
    required this.onImportTap,
    this.onLibrarySubTabChanged,
    this.onLibraryCountsChanged,
  }) : super(key: key);

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  int _selectedTabIndex = 0;
  List<DocumentFile> _favoritedDocuments = [];
  List<DocumentFile> _bookmarkedDocuments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLibrarySubTabChanged?.call(_selectedTabIndex);
    });
  }
  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await StorageService.getFavorites();
      final bookmarks = await StorageService.getBookmarks();

      setState(() {
        _favoritedDocuments = favorites;
        _bookmarkedDocuments = bookmarks;
        _isLoading = false;
      });
      
      // Notify parent about counts
      widget.onLibraryCountsChanged?.call(favorites.length, bookmarks.length);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      widget.onLibraryCountsChanged?.call(0, 0);
    }
  }


  Map<String, dynamic> _documentFileToMap(DocumentFile document) {
    return {
      'id': document.id,
      'name': document.displayName,
      'type': document.name.split('.').last,
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
    final favoriteCount = _favoritedDocuments.length;
    final bookmarkCount = _bookmarkedDocuments.length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBarWithActions(favoriteCount, bookmarkCount),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarWithActions(int favoriteCount, int bookmarkCount) {

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
      child: Column(
        children: [
          // Tab bar
          CustomSlidingSegment(
            tabs: [
              SegmentTab(title: "Favorites", count: favoriteCount, icon: Icons.favorite),
              SegmentTab(title: "Bookmarks", count: bookmarkCount, icon: Icons.bookmark),
            ],
            selectedIndex: _selectedTabIndex,
            onSelectionChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
              widget.onLibrarySubTabChanged?.call(index);
            },
            animationDuration: const Duration(milliseconds: 250),
            selectedColor: Theme.of(context).colorScheme.primary,
            unselectedColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            borderColor: Theme.of(context).colorScheme.outline.withValues(),
            height: 48,
            borderRadius: 22,
            showShadow: true,
          ),
          
          // Action buttons (only show when there are items)
          // if (hasItems) ...[
          //   SizedBox(height: 2.w),
          //   Container(
          //     padding: EdgeInsets.all(3.w),
          //     margin: EdgeInsets.fromLTRB(0.w, 1.w, 1.w, 0.w),
          //     decoration: BoxDecoration(
          //       color: Theme.of(context).cardColor,
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //     child:Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       TextButton.icon(
          //         onPressed: _selectedTabIndex == 0 ? _clearFavorites : _clearBookmarks,
          //         icon: Icon(
          //           Icons.clear_all,
          //           size: 16,
          //           color: Theme.of(context).colorScheme.primary,
          //         ),
          //         label: Text(
          //           'Clear ${_selectedTabIndex == 0 ? 'Favorites' : 'Bookmarks'}',
          //           style: TextStyle(
          //             color: Theme.of(context).colorScheme.primary,
          //             fontSize: 12,
          //           ),
          //         ),
          //         style: TextButton.styleFrom(
          //           padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
          //           minimumSize: Size.zero,
          //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //         ),
          //       ),
          //     ],
          //   ),
          //   )
          // ],
        ],
      ),
    );
  }

  void _showLibraryQuickActions(DocumentFile document) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFavorite = _favoritedDocuments.any((doc) => doc.path == document.path);
    final isBookmarked = _bookmarkedDocuments.any((doc) => doc.path == document.path);
    final isInFavoritesTab = _selectedTabIndex == 0;
    final isInBookmarksTab = _selectedTabIndex == 1;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(4.w, 4.w, 4.w, 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onFileOpen(document);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                      Icons.open_in_new,
                      color: colorScheme.primary,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'open',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),),
                  ],
                ),
              ),
            ),
            
            // Only show favorite toggle if not in favorites tab or if it's to add to favorites
            if (!isInFavoritesTab || !isFavorite)
            GestureDetector(
              onTap: () async{
                Navigator.pop(context);
                await _toggleFavorite(document);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : colorScheme.onSurface,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      isFavorite
                          ? 'Removed from favorites'
                          : 'Added to favorites',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),),
                  ],
                ),
              ),
            ),
            // Only show bookmark toggle if not in bookmarks tab or if it's to add to bookmarks
            if (!isInBookmarksTab || !isBookmarked)
            GestureDetector(
              onTap: () async{
                Navigator.pop(context);
                await _toggleBookmark(document);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () async{
                Navigator.pop(context);
                await _shareDocument(document);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                child: Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Colors.lightBlueAccent,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Share',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),),
                  ],
                ),
              ),
            ),
            // Remove from current list (context-aware)
            GestureDetector(
              onTap: () async{
                Navigator.pop(context);
                if (isInFavoritesTab) {
                  await _removeFromFavorites(document);
                } else {
                  await _removeFromBookmarks(document);
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
                  Text(isInFavoritesTab 
                  ? 'Remove from Favorites' 
                  : 'Remove from Bookmarks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),),
                ],
              ),
            ),
            ),
            
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(DocumentFile document) async {
    try {
      final isFavorite = _favoritedDocuments.any((doc) => doc.path == document.path);
      if (isFavorite) {
        await StorageService.removeFavorite(document.path);
        setState(() {
          _favoritedDocuments.removeWhere((doc) => doc.path == document.path);
        });
      } else {
        await StorageService.addFavorite(document);
        setState(() {
          _favoritedDocuments.add(document);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _toggleBookmark(DocumentFile document) async {
    try {
      final isBookmarked = _bookmarkedDocuments.any((doc) => doc.path == document.path);
      if (isBookmarked) {
        await StorageService.removeBookmark(document.path);
        setState(() {
          _bookmarkedDocuments.removeWhere((doc) => doc.path == document.path);
        });
      } else {
        await StorageService.addBookmark(document);
        setState(() {
          _bookmarkedDocuments.add(document);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _removeFromFavorites(DocumentFile document) async {
    try {
      await StorageService.removeFavorite(document.path);
      setState(() {
        _favoritedDocuments.removeWhere((doc) => doc.path == document.path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from favorites'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeFromBookmarks(DocumentFile document) async {
    try {
      await StorageService.removeBookmark(document.path);
      setState(() {
        _bookmarkedDocuments.removeWhere((doc) => doc.path == document.path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from bookmarks'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from bookmarks'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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


  Widget _buildTabContent() {
    List<DocumentFile> currentList;
    String emptyMessage;

    switch (_selectedTabIndex) {
      case 0:
        currentList = _favoritedDocuments;
        emptyMessage =
            "No favorites yet\nTap the heart icon on any document to add it to favorites";
        break;
      case 1:
        currentList = _bookmarkedDocuments;
        emptyMessage =
            "No bookmarks yet\nTap the bookmark icon on any document to save it here";
        break;
      default:
        currentList = [];
        emptyMessage = "No data available";
    }

    if (currentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTabIndex == 0
                  ? Icons.favorite_border
                  : Icons.bookmark_border,
              size: 15.w,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: 2.h),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(0, 0.h, 0, 10.h),
        itemCount: currentList.length,
        itemBuilder: (context, index) {
          final document = currentList[index];
          return DocumentCardWidget(
            document: _documentFileToMap(document),
            onTap: () => widget.onFileOpen(document),
            onOptionTap: () => _showLibraryQuickActions(document),
            onLongPress: () => _showLibraryQuickActions(document),
            isSelected: false,
            isSelectionMode: false,
          );
        },
      ),
    );
  }

}
