import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdfviewer/models/document_file.dart';
import 'package:pdfviewer/presentation/all_file_screen/all_file_screen.dart';
import 'package:pdfviewer/presentation/dashboard_screen/widgets/tab_bar_widget.dart';
import 'package:pdfviewer/presentation/document_viewer/file_reader_screen.dart';
import 'package:pdfviewer/presentation/library_screen/library_screen.dart';
import 'package:pdfviewer/presentation/recent_screen/recent_screen.dart';
import 'package:pdfviewer/presentation/settings_and_preferences/settings_and_preferences.dart';
import 'package:pdfviewer/services/permission_service.dart';
import 'package:pdfviewer/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import 'widgets/search_bar_widget.dart';

class FileListDashboard extends StatefulWidget {
  const FileListDashboard({Key? key}) : super(key: key);

  @override
  State<FileListDashboard> createState() => _FileListDashboardState();
}

class _FileListDashboardState extends State<FileListDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _currentSortOption = 'date';
  List<String> _activeFilters = [];
  bool _hasPermission = false;
  int _currentTabIndex = 0;
  late ScrollController _scrollController;
  final List<String> _tabLabels = ['Files', 'Recent', 'Library', 'Settings'];
  
  // Add this state variable to track selection mode from child screens
  bool _isChildSelectionMode = false;
  int _librarySubTabIndex = 0;
  int _recentFilesCount = 0;
  int _favoritesCount = 0;
  int _bookmarksCount = 0;
  final GlobalKey<RecentScreenState> _recentScreenKey = GlobalKey();
  final GlobalKey<LibraryScreenState> _libraryScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
    // This listener handles BOTH tapping AND swiping
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
          // Reset search and filters when switching tabs
          if (_currentTabIndex == 2 || _currentTabIndex == 3) {
            _activeFilters.clear();
            _searchQuery = '';
          }
          // Reset selection mode when switching tabs
          _isChildSelectionMode = false;
        });
      }
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Initialize StorageService
    await StorageService.init();
  }

  void _handleLibrarySubTabChanged(int subTabIndex) {
    setState(() {
      _librarySubTabIndex = subTabIndex;
    });
    log('Library sub-tab changed to: ${subTabIndex == 0 ? "Favorites" : "Bookmarks"}');
  }
  void _handleRecentFilesCountChanged(int count) {
    setState(() {
      _recentFilesCount = count;
    });
    log('Recent files count: $count');
  }

  void _handleLibraryCountsChanged(int favCount, int bookmarkCount) {
    setState(() {
      _favoritesCount = favCount;
      _bookmarksCount = bookmarkCount;
    });
    log('Favorites: $favCount, Bookmarks: $bookmarkCount');
  }
  // Add this method to handle selection mode changes from child screens
  void _handleSelectionModeChanged(bool isSelectionMode) {
    log('Selection mode changed: $isSelectionMode');
    log('FAB visibility: ${!isSelectionMode}');
    setState(() {
      _isChildSelectionMode = isSelectionMode;
    });
  }

  Future<void> _checkPermissionStatus() async {
    final result = await PermissionService.checkAndRequestStoragePermission();

    setState(() {
      _hasPermission = result.isGranted;
    });

    if (!result.isGranted) {
      _showPermissionDialog(result);
    }
  }

  void _showPermissionDialog(PermissionResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Permission Required'),
        content: Text(result.message),
        actions: [
          if (result.shouldShowSettings)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Open Settings'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPermissionStatus();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  static Future<DocumentFile?> pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final stat = await file.stat();
        final name = file.path.split('/').last;
        final displayName = name
            .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
            .replaceAll(RegExp(r'[_-]+'), ' ')
            .trim();
        return DocumentFile(
          path: file.path,
          name: name,
          displayName: displayName,
          size: stat.size,
          lastModified: stat.modified,
        );
      }
    } catch (_) {}
    return null;
  }

  void _openFile(DocumentFile documentFile) async {
    // Navigate to file reader
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileReaderScreen(documentFile: documentFile),
      ),
    );
  }

  void _pickAndOpenFile() async {
    final documentFile = await pickDocumentFile();
    if (documentFile != null) {
      _openFile(documentFile);
    } else {
      print('No file selected or error occurred');
    }
  }
  

  @override
  Widget build(BuildContext context) {
    log('Current tab index: $_currentTabIndex');
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // App Bar
                SliverAppBar(
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  floating: false,
                  pinned: false,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(background: _buildAppBar()),
                  expandedHeight: 50,
                ),
                if (_currentTabIndex == 0 || _currentTabIndex == 1)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      minHeight: 60,
                      maxHeight: 60,
                      child: Container(
                        alignment: Alignment.center,
                        color: Theme.of(context).colorScheme.surface,
                        child: SearchBarWidget(
                          onSearchChanged: _performSearch,
                          onFilterTap: _showSortBottomSheets,
                        ),
                      ),
                    ),
                  ),
                // Sticky TabBar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    minHeight: 45,
                    maxHeight: 45,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: TabBarWidget(
                        tabController: _tabController,
                        tabLabels: _tabLabels,
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Container(
              color: isLightTheme
                  ? AppTheme.backgroundLight
                  : theme.scaffoldBackgroundColor,
              child: _buildContent(),
            ),
          ),
        ),
        // Update FAB visibility: hide when selection mode is active
        floatingActionButton: (_currentTabIndex == 0 || _currentTabIndex == 1) && !_isChildSelectionMode
            ? FloatingActionButton(
                onPressed: _pickAndOpenFile,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: CustomIconWidget(
                  iconName: 'add',
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 6.w,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildContent() {
    // Show permission denied state
    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'folder_off',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Storage Permission Required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please grant storage permission to access your documents',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () async {
                await _checkPermissionStatus();
                setState(() {});
              },
              child: Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      key: ValueKey(Theme.of(context).brightness),
      controller: _tabController,
      children: [
        // Files Tab - Pass the callback
        AllFileScreen(
          searchQuery: _searchQuery,
          activeFilters: _activeFilters,
          currentSortOption: _currentSortOption,
          onFileOpen: _openFile,
          onImportTap: _showImportActionSheet,
          onSelectionModeChanged: _handleSelectionModeChanged, // Add this callback
        ),

        // Recent Tab - Pass the callback
        RecentScreen(
          key: _recentScreenKey,
          searchQuery: _searchQuery,
          activeFilters: _activeFilters,
          currentSortOption: _currentSortOption,
          onFileOpen: _openFile,
          onImportTap: _showImportActionSheet,
          onRecentFilesCountChanged: _handleRecentFilesCountChanged,
        ),

        LibraryScreen(
          key: _libraryScreenKey,
          onFileOpen: _openFile,
          onImportTap: _showImportActionSheet,
          onLibrarySubTabChanged: _handleLibrarySubTabChanged,
          onLibraryCountsChanged: _handleLibraryCountsChanged,
        ),

        SettingsAndPreferences(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          // App Icon Container
          Container(
            width: 8.w,
            height: 8.w,
            margin: EdgeInsets.only(right: 1.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/logo.png',
                width: 25,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // App Name
          Expanded(
            child: Text(
              'PDFViewer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          // Settings Button
          if (_currentTabIndex == 0) // Files Tab - Select/Multi-select button
            GestureDetector(
              onTap: () {
                // TODO: Implement multi-select mode for Files tab
                print('Select mode activated for Files');
              },
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: CustomIconWidget(
                  iconName: 'select_multiple',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 5.w,
                ),
              ),
            )
          else if (_currentTabIndex == 1  && _recentFilesCount > 0) // Recent Tab - Delete/Clear Recent button
            GestureDetector(
              onTap: () {
                // Show dialog to clear recent files
                _showClearRecentDialog();
              },
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child:Row(
                  children: [
                    Text(
                      'Clear',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    CustomIconWidget(
                    iconName: 'delete',
                    color: Theme.of(context).colorScheme.error,
                    size: 5.w,
                    )

                  ],
                  ),
                
              ),
            )
          else if (_currentTabIndex == 2)
            if ((_librarySubTabIndex == 0 && _favoritesCount > 0) || 
              (_librarySubTabIndex == 1 && _bookmarksCount > 0))
            GestureDetector(
              onTap: () {
                // Show different dialogs based on library sub-tab
                if (_librarySubTabIndex == 0) {
                  _showClearFavoritesDialog();
                } else {
                  _showClearBookmarksDialog();
                }
              },
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child:Row(
                  children: [
                    Text(
                      'Clear',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      child: CustomIconWidget(
                        key: ValueKey(_librarySubTabIndex),
                        iconName: _librarySubTabIndex == 0 ? 'favorite' : 'bookmark',
                        color: Theme.of(context).colorScheme.error,
                        size: 5.w,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
        ],
      ),
    );
  }

  void _showSortBottomSheets() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogTheme.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Text(
                  'Sort Files By',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 4.h),

                // Sort Options Row with proper spacing
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildSortOption('name', 'text_fields', 'Name'),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildSortOption('date', 'schedule', 'Date'),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildSortOption('size', 'data_usage', 'Size'),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String value, String iconName, String label) {
    final isSelected = _currentSortOption == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSortOption = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 1.5.h,
          horizontal: 1.w,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 4.w,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  void _showImportActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Scan Document'),
              onTap: () {
                Navigator.pop(context);
                // Add scan logic
              },
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text('Browse Files'),
              onTap: () {
                Navigator.pop(context);
                // Add browse logic
              },
            ),
          ],
        ),
      ),
    );
  }
  void _showClearRecentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Clear Recent Files'),
          content: Text(
            'Are you sure you want to clear all recent files? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Clear the data
                await StorageService.clearRecentFiles();
                
                // Trigger refresh in RecentScreen
                _recentScreenKey.currentState?.refreshFiles();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recent files cleared'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showClearFavoritesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Clear Favorites'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 48,
                color: Colors.red.withValues(alpha: 0.7),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to clear all favorites? This action cannot be undone.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Clear the data
                await StorageService.clearFavorites();
                
                // Trigger refresh in LibraryScreen
                _libraryScreenKey.currentState?.refreshData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Favorites cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Clear Favorites'),
            ),
          ],
        );
      },
    );
  }

  void _showClearBookmarksDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Clear Bookmarks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to clear all bookmarks? This action cannot be undone.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Clear the data
                await StorageService.clearBookmarks();
                
                // Trigger refresh in LibraryScreen
                _libraryScreenKey.currentState?.refreshData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bookmarks cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Clear Bookmarks'),
            ),
          ],
        );
      },
    );
  }
}

// Custom delegate for sticky headers
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent ||
        minHeight != oldDelegate.minExtent;
  }
}