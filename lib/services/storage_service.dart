import 'dart:convert';
import 'dart:io';
import 'package:pdfviewer/models/document_file.dart';
import 'package:pdfviewer/services/pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _bookmarksKey = 'bookmarks';
  static const String _recentFilesKey = 'recent_files';
  static const String _settingsKey = 'app_settings';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Favorites management
  static Future<List<DocumentFile>> getFavorites() async {
    final favorites = _prefs?.getStringList(_favoritesKey) ?? [];
    return favorites
        .map((json) => DocumentFile.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> addFavorite(DocumentFile pdfFile) async {
    final favorites = await getFavorites();
    final exists = favorites.any((f) => f.path == pdfFile.path);
    if (!exists) {
      favorites.add(pdfFile.copyWith(isFavorite: true));
      await _saveFavorites(favorites);
    }
  }

  static Future<void> removeFavorite(String path) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) => f.path == path);
    await _saveFavorites(favorites);
  }

  static Future<bool> isFavorite(String path) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f.path == path);
  }

  static Future<void> _saveFavorites(List<DocumentFile> favorites) async {
    final jsonList = favorites.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs?.setStringList(_favoritesKey, jsonList);
  }

  static Future<void> clearFavorites() async {
    await _prefs?.remove(_favoritesKey);
  }

  // Bookmarks management
  static Future<List<DocumentFile>> getBookmarks() async {
    final bookmarks = _prefs?.getStringList(_bookmarksKey) ?? [];
    return bookmarks
        .map((json) => DocumentFile.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> addBookmark(DocumentFile pdfFile) async {
    final bookmarks = await getBookmarks();
    final exists = bookmarks.any((f) => f.path == pdfFile.path);
    if (!exists) {
      bookmarks.add(pdfFile.copyWith(isBookmarked: true));
      await _saveBookmarks(bookmarks);
    }
  }

  static Future<void> removeBookmark(String path) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((f) => f.path == path);
    await _saveBookmarks(bookmarks);
  }

  static Future<bool> isBookmarked(String path) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((f) => f.path == path);
  }

  static Future<void> _saveBookmarks(List<DocumentFile> bookmarks) async {
    final jsonList = bookmarks.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs?.setStringList(_bookmarksKey, jsonList);
  }

  static Future<void> clearBookmarks() async {
    await _prefs?.remove(_bookmarksKey);
  }

  // Recent files management
  static Future<List<DocumentFile>> getRecentFiles() async {
    final recentFiles = _prefs?.getStringList(_recentFilesKey) ?? [];
    final files = recentFiles
        .map((json) => DocumentFile.fromJson(jsonDecode(json)))
        .toList();
    files.sort(
      (a, b) =>
          (b.lastOpened ?? DateTime(0)).compareTo(a.lastOpened ?? DateTime(0)),
    );
    return files.take(20).toList(); // Keep only 20 most recent
  }


  static Future<void> addRecentFile(DocumentFile pdfFile) async {
    final recentFiles = await getRecentFiles();
    recentFiles.removeWhere((f) => f.path == pdfFile.path);
    recentFiles.insert(0, pdfFile.copyWith(lastOpened: DateTime.now()));

    // Keep only 20 most recent
    if (recentFiles.length > 20) {
      recentFiles.removeRange(20, recentFiles.length);
    }

    await _saveRecentFiles(recentFiles);
  }

  static Future<void> clearRecentFiles() async {
    await _prefs?.remove(_recentFilesKey);
  }
  static Future<void> deleteRecentFile(String path) async {
    final recentFiles = await getRecentFiles();
    recentFiles.removeWhere((f) => f.path == path);
    await _saveRecentFiles(recentFiles);
  }

  static Future<void> _saveRecentFiles(List<DocumentFile> recentFiles) async {
    final jsonList = recentFiles.map((f) => jsonEncode(f.toJson())).toList();
    await _prefs?.setStringList(_recentFilesKey, jsonList);
  }

  // App settings
  static Future<Map<String, dynamic>> getSettings() async {
    final settingsJson = _prefs?.getString(_settingsKey) ?? '{}';
    return jsonDecode(settingsJson);
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await _prefs?.setString(_settingsKey, jsonEncode(settings));
  }

  static Future<T?> getSetting<T>(String key, [T? defaultValue]) async {
    final settings = await getSettings();
    return settings[key] as T? ?? defaultValue;
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _prefs?.remove(_favoritesKey);
    await _prefs?.remove(_bookmarksKey);
    await _prefs?.remove(_recentFilesKey);
  }
  // Add this to your StorageService class

// All PDF files management (using FileService)
static Future<List<DocumentFile>> getAllPdfFiles({bool forceRefresh = false}) async {
  return await FileService.scanForFiles(forceRefresh: forceRefresh);
}

static Future<List<DocumentFile>> getAllPdfFilesCached() async {
  if (FileService.isCacheValid()) {
    return FileService.getCachedFiles();
  }
  return await getAllPdfFiles();
}

static Future<void> refreshAllPdfFiles() async {
  await FileService.refreshCache();
}

static Future<List<DocumentFile>> searchPdfFiles(String query) async {
  return await FileService.searchFiles(query);
}

// Stats functions that can use the cached data
static Future<Map<String, dynamic>> getPdfFileStats() async {
  final allFiles = await getAllPdfFilesCached();
  final favorites = await getFavorites();
  final bookmarks = await getBookmarks();
  final recentFiles = await getRecentFiles();
  
  // Calculate total size
  int totalSize = 0;
  for (final file in allFiles) {
    totalSize += file.size;
  }
  
  // Group by month for recent activity
  final now = DateTime.now();
  final thisMonth = allFiles.where((file) {
    return file.lastModified.year == now.year && 
           file.lastModified.month == now.month;
  }).length;
  
  final lastMonth = allFiles.where((file) {
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    return file.lastModified.year == lastMonthDate.year && 
           file.lastModified.month == lastMonthDate.month;
  }).length;
  
  // Find largest files
  final sortedBySize = List<DocumentFile>.from(allFiles)
    ..sort((a, b) => b.size.compareTo(a.size));
  final largestFiles = sortedBySize.take(5).toList();
  
  return {
    'totalFiles': allFiles.length,
    'totalSize': totalSize,
    'totalFavorites': favorites.length,
    'totalBookmarks': bookmarks.length,
    'totalRecentFiles': recentFiles.length,
    'filesThisMonth': thisMonth,
    'filesLastMonth': lastMonth,
    'largestFiles': largestFiles.map((f) => {
      'name': f.displayName,
      'size': f.size,
      'path': f.path,
    }).toList(),
    'cacheLastUpdated': FileService.isCacheValid() ? 'Valid' : 'Expired',
  };
}

 

// Get files by size range for analytics
static Future<Map<String, int>> getFilesBySize() async {
  final allFiles = await getAllPdfFilesCached();
  
  int small = 0; // < 1MB
  int medium = 0; // 1MB - 10MB
  int large = 0; // > 10MB
  
  for (final file in allFiles) {
    if (file.size < 1024 * 1024) {
      small++;
    } else if (file.size < 10 * 1024 * 1024) {
      medium++;
    } else {
      large++;
    }
  }
  
  return {
    'small': small,
    'medium': medium,
    'large': large,
  };
}

// Get recently modified files
static Future<List<DocumentFile>> getRecentlyModifiedFiles({int days = 7}) async {
    final allFiles = await getAllPdfFilesCached();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return allFiles.where((file) => 
      file.lastModified.isAfter(cutoffDate)
    ).toList();
  }


/// Deletes a DocumentFile from device storage and removes it from all lists
static Future<bool> deleteDocumentFile(DocumentFile documentFile) async {
  try {
      final file = File(documentFile.path);
      
      // Check if file exists before attempting to delete
      if (await file.exists()) {
        // Delete the actual file from storage
        await file.delete();
        
        // Clean up from all storage lists
        await _cleanupDeletedFile(documentFile.path);
        
        return true;
      } else {
        // File doesn't exist, but still clean up from lists in case it's orphaned
        await _cleanupDeletedFile(documentFile.path);
        return false; // File didn't exist
      }
  } catch (e) {
    return false;
  }
}

/// Deletes multiple DocumentFiles from device storage
static Future<Map<String, bool>> deleteMultipleDocumentFiles(List<DocumentFile> documentFiles) async {
  Map<String, bool> results = {};
  
  for (final document in documentFiles) {
    results[document.path] = await deleteDocumentFile(document);
  }
  
  return results;
}

/// Internal method to clean up a deleted file from all storage lists
static Future<void> _cleanupDeletedFile(String filePath) async {
  // Remove from favorites
  await removeFavorite(filePath);
  
  // Remove from bookmarks  
  await removeBookmark(filePath);
  
  // Remove from recent files
  await deleteRecentFile(filePath);
}

/// Deletes file by path only (useful when you only have the path)
static Future<bool> deleteFileByPath(String filePath) async {
  try {
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
      await _cleanupDeletedFile(filePath);
      return true;
    } else {
      await _cleanupDeletedFile(filePath);
      return false;
    }
  } catch (e) {
    return false;
  }
}

/// Checks if a file still exists on the device
static Future<bool> fileExists(String filePath) async {
  try {
    final file = File(filePath);
    return await file.exists();
  } catch (e) {
    return false;
  }
}

/// Validates and cleans up orphaned entries (files that no longer exist)
static Future<void> cleanupOrphanedEntries() async {
    // Clean up favorites
    final favorites = await getFavorites();
    final validFavorites = <DocumentFile>[];
    
    for (final favorite in favorites) {
      if (await fileExists(favorite.path)) {
        validFavorites.add(favorite);
      }
    }
    await _saveFavorites(validFavorites);
    
    // Clean up bookmarks
    final bookmarks = await getBookmarks();
    final validBookmarks = <DocumentFile>[];
    
    for (final bookmark in bookmarks) {
      if (await fileExists(bookmark.path)) {
        validBookmarks.add(bookmark);
      }
    }
    await _saveBookmarks(validBookmarks);
    
    // Clean up recent files
    final recentFiles = await getRecentFiles();
    final validRecentFiles = <DocumentFile>[];
    
    for (final recent in recentFiles) {
      if (await fileExists(recent.path)) {
        validRecentFiles.add(recent);
      }
    }
    await _saveRecentFiles(validRecentFiles);
  }


}
