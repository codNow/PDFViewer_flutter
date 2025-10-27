import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfviewer/models/document_file.dart';
import 'package:pdfviewer/services/storage_service.dart';

class FileService {
  static List<DocumentFile> _cacheAllFiles = [];
  static DateTime? _lastScanTime;
  static const int _cacheValidityMinutes = 5;

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Prefer MANAGE_EXTERNAL_STORAGE for broad file access on Android 11+
      final manage = Permission.manageExternalStorage;
      final manageStatus = await manage.status;
      if (manageStatus.isGranted) {
        return true;
      }

      if (manageStatus.isDenied) {
        final manageResult = await manage.request();
        if (manageResult.isGranted) {
          return true;
        }
      }

      if (manageStatus.isPermanentlyDenied || manageStatus.isRestricted) {
        // Guide user to enable "All files access" in Settings
        await openAppSettings();
        return false;
      }

      // Fallback for older Android versions
      final storageResult = await Permission.storage.request();
      return storageResult.isGranted;
    }
    return true; // iOS handles permissions automatically
  }

  static Future<List<DocumentFile>> scanForFiles({bool forceRefresh = false}) async {
    // Check if we should use cache
    bool shouldUseCache = false;
    if (!forceRefresh && _cacheAllFiles.isNotEmpty && _lastScanTime != null) {
      final timeDiff = DateTime.now().difference(_lastScanTime!);
      if (timeDiff.inMinutes < _cacheValidityMinutes) {
        shouldUseCache = true;
      }
    }

    // If using cache, return enriched cached data
    if (shouldUseCache) {
      print('Using cached files: ${_cacheAllFiles.length}');
      return await _enrichFilesWithUserData(_cacheAllFiles);
    }

    // Otherwise, perform fresh scan
    print('Performing fresh scan...');
    if (!await requestStoragePermission()) {
      return [];
    }

    final List<DocumentFile> allFiles = [];
    final Set<String> seenPaths = {}; // Simple path-based deduplication

    // Simple approach: Just scan the root storage like React Native
    await _scanRootStorage(allFiles, seenPaths);

    print('Found ${allFiles.length} unique files');
    
    // Sort by last modified (newest first)
    allFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    
    print('Final file count: ${allFiles.length}');
    
    // Update cache
    _cacheAllFiles = allFiles;
    _lastScanTime = DateTime.now();
    
    // Return enriched data
    return await _enrichFilesWithUserData(allFiles);
  }

  static Future<void> _scanRootStorage(List<DocumentFile> allFiles, Set<String> seenPaths) async {
    // Primary storage paths to try (similar to React Native's single root approach)
    final List<String> rootPaths = [
      '/storage/emulated/0',
      '/sdcard',
    ];

    String? workingRootPath;
    
    // Find the first accessible root path
    for (final rootPath in rootPaths) {
      try {
        final directory = Directory(rootPath);
        if (await directory.exists()) {
          // Test if we can actually list contents
          await directory.list().take(1).toList();
          workingRootPath = rootPath;
          print('Using root storage path: $rootPath');
          break;
        }
      } catch (e) {
        print('Cannot access $rootPath: $e');
        continue;
      }
    }

    if (workingRootPath == null) {
      print('No accessible root storage path found');
      return;
    }

    // Scan from the single root path (like React Native)
    final rootDirectory = Directory(workingRootPath);
    await _deepScanDirectory(rootDirectory, allFiles, seenPaths, 0);
  }

  static Future<void> _deepScanDirectory(
    Directory directory, 
    List<DocumentFile> allFiles, 
    Set<String> seenPaths,
    int depth
  ) async {
    // Prevent infinite recursion and limit depth for performance
    if (depth > 10) {
      print('Max depth reached for: ${directory.path}');
      return;
    }

    try {
      final dirPath = directory.path;
      final lowerDirPath = dirPath.toLowerCase();
      
      // Skip system and cache directories (similar to React Native filtering)
      final skipPatterns = [
        '/android/data',
        '/android/obb', 
        '/.thumbnails',
        '/.cache',
        '/cache',
        '/data/data',
        '/proc',
        '/sys',
        '/dev',
      ];
      
      // Skip if this directory matches any skip pattern
      if (skipPatterns.any((pattern) => lowerDirPath.contains(pattern))) {
        return;
      }

      // Skip hidden directories and common temp/cache patterns
      final dirName = dirPath.split('/').last.toLowerCase();
      if (dirName.startsWith('.') || 
          dirName.contains('cache') || 
          dirName.contains('temp') ||
          dirName.contains('tmp')) {
        return;
      }

      print('Scanning: $dirPath (depth: $depth)');

      try {
        await for (final entity in directory.list(followLinks: false)) {
          if (entity is File) {
            await _processFile(entity, allFiles, seenPaths);
          } else if (entity is Directory) {
            // Recursively scan subdirectories
            await _deepScanDirectory(entity, allFiles, seenPaths, depth + 1);
          }
        }
      } catch (e) {
        print('Error listing contents of ${directory.path}: $e');
      }

    } catch (e) {
      print('Error scanning directory ${directory.path}: $e');
    }
  }

  static Future<void> _processFile(File file, List<DocumentFile> allFiles, Set<String> seenPaths) async {
    try {
      final filePath = file.path;
      
      // Skip if we've already processed this exact file path
      if (seenPaths.contains(filePath)) {
        return;
      }

      final lowerPath = filePath.toLowerCase();
      
      // Skip cache/temp files
      if (lowerPath.contains('/cache/') || 
          lowerPath.contains('/tmp/') || 
          lowerPath.contains('/.cache/') ||
          lowerPath.contains('/thumbnails/') ||
          lowerPath.contains('/.thumbnails/')) {
        return;
      }

      // Check if it's a PDF file
      if (!lowerPath.endsWith('.pdf')) {
        return;
      }

      // Verify the file actually exists and is accessible
      if (!await file.exists()) {
        return;
      }

      final stat = await file.stat();
      
      // Skip zero-byte files (likely broken or incomplete)
      if (stat.size == 0) {
        return;
      }

      final name = filePath.split('/').last;
      final displayName = name
          .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .trim();
      
      final documentFile = DocumentFile(
        path: filePath,
        name: name,
        displayName: displayName,
        size: stat.size,
        lastModified: stat.modified,
      );
      
      // Mark this path as seen and add the file
      seenPaths.add(filePath);
      allFiles.add(documentFile);
      print('Found: ${name} (${stat.size} bytes)');
      
    } catch (e) {
      print('Error processing file ${file.path}: $e');
    }
  }

  static Future<List<DocumentFile>> _enrichFilesWithUserData(List<DocumentFile> allFiles) async {
    final favorites = await StorageService.getFavorites();
    final bookmarks = await StorageService.getBookmarks();
    final recentFiles = await StorageService.getRecentFiles();
    
    return allFiles.map((file) {
      final isFavorite = favorites.any((f) => f.path == file.path);
      final isBookmarked = bookmarks.any((b) => b.path == file.path);
      final recentFile = recentFiles.cast<DocumentFile?>().firstWhere((r) => r?.path == file.path, orElse: () => null);
      
      return file.copyWith(
        isFavorite: isFavorite,
        isBookmarked: isBookmarked,
        lastOpened: recentFile?.lastOpened,
      );
    }).toList();
  }

  static Future<List<DocumentFile>> searchFiles(String query) async {
    final allFiles = await scanForFiles();
    if (query.isEmpty) return allFiles;
    
    final lowercaseQuery = query.toLowerCase();
    return allFiles.where((file) {
      return file.displayName.toLowerCase().contains(lowercaseQuery) ||
            file.name.toLowerCase().contains(lowercaseQuery) ||
            file.path.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  static Future<DocumentFile?> pickFile() async {
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
    } catch (e) {
      print('Error picking file: $e');
    }
    
    return null;
  }

  static Future<void> refreshCache() async {
    _cacheAllFiles.clear();
    _lastScanTime = null;
    await scanForFiles(forceRefresh: true);
  }

  static List<DocumentFile> getCachedFiles() => _cacheAllFiles;

  static Future<List<DocumentFile>> getFreshFiles() async {
    _cacheAllFiles.clear();
    _lastScanTime = null;
    return await scanForFiles(forceRefresh: true);
  }

  static bool isCacheValid() {
    if (_lastScanTime == null) return false;
    final timeDiff = DateTime.now().difference(_lastScanTime!);
    return timeDiff.inMinutes < _cacheValidityMinutes;
  }

  static void debugPrintFiles(List<DocumentFile> files) {
    print('=== DEBUG: All found PDF files ===');
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      print('${i + 1}. ${file.name}');
      print('   Path: ${file.path}');
      print('   Size: ${file.size} bytes');
      print('   Modified: ${file.lastModified}');
      print('   ---');
    }
    print('=== END DEBUG ===');
  }
}
