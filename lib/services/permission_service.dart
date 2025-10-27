import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Private constructor to prevent direct instantiation
  PermissionService._();
  
  // Singleton instance
  static final PermissionService _instance = PermissionService._();
  
  // Factory constructor returns the singleton instance
  factory PermissionService() => _instance;
  
  // Static getter for easier access
  static PermissionService get instance => _instance;
  
  /// Checks if storage permission is currently granted
  static Future<bool> isStoragePermissionGranted() async {
    if (Platform.isAndroid) {
      // Check MANAGE_EXTERNAL_STORAGE first for Android 11+
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) {
        return true;
      }
      
      // Fallback to regular storage permission for older versions
      final storageStatus = await Permission.storage.status;
      return storageStatus.isGranted;
    }
    
    return true; // iOS handles permissions automatically
  }
  
  /// Requests storage permission from user
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
  
  /// Comprehensive permission status check
  static Future<Map<String, dynamic>> getStoragePermissionStatus() async {
    if (Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.status;
      final storageStatus = await Permission.storage.status;
      
      return {
        'isGranted': manageStatus.isGranted || storageStatus.isGranted,
        'manageExternalStorage': {
          'isGranted': manageStatus.isGranted,
          'isDenied': manageStatus.isDenied,
          'isPermanentlyDenied': manageStatus.isPermanentlyDenied,
          'isRestricted': manageStatus.isRestricted,
          'status': manageStatus.toString(),
        },
        'storage': {
          'isGranted': storageStatus.isGranted,
          'isDenied': storageStatus.isDenied,
          'isPermanentlyDenied': storageStatus.isPermanentlyDenied,
          'isRestricted': storageStatus.isRestricted,
          'status': storageStatus.toString(),
        },
      };
    }
    
    return {
      'isGranted': true,
      'platform': 'iOS - permissions handled automatically'
    };
  }
  
  /// Get human-readable permission status description
  static Future<String> getPermissionStatusDescription() async {
    if (Platform.isAndroid) {
      final manageStatus = await Permission.manageExternalStorage.status;
      final storageStatus = await Permission.storage.status;
      
      if (manageStatus.isGranted || storageStatus.isGranted) {
        return 'Permission granted - full access available';
      } else if (manageStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        return 'Permission permanently denied - user must enable in settings';
      } else if (manageStatus.isRestricted || storageStatus.isRestricted) {
        return 'Permission restricted by system';
      } else {
        return 'Permission denied - can request permission';
      }
    }
    
    return 'iOS - permissions handled automatically';
  }
  
  /// Check and request permission with proper handling
  static Future<PermissionResult> checkAndRequestStoragePermission() async {
    final isGranted = await isStoragePermissionGranted();
    
    if (isGranted) {
      return PermissionResult(
        isGranted: true,
        message: 'Permission already granted',
        shouldShowSettings: false,
      );
    }
    
    final granted = await requestStoragePermission();
    
    if (granted) {
      return PermissionResult(
        isGranted: true,
        message: 'Permission granted successfully',
        shouldShowSettings: false,
      );
    }
    
    final status = await getStoragePermissionStatus();
    final isPermanentlyDenied = Platform.isAndroid && 
        (status['manageExternalStorage']['isPermanentlyDenied'] == true ||
         status['storage']['isPermanentlyDenied'] == true);
    
    return PermissionResult(
      isGranted: false,
      message: isPermanentlyDenied 
          ? 'Permission permanently denied. Please enable in settings.'
          : 'Permission denied',
      shouldShowSettings: isPermanentlyDenied,
    );
  }
}

/// Result class for permission operations
class PermissionResult {
  final bool isGranted;
  final String message;
  final bool shouldShowSettings;
  
  const PermissionResult({
    required this.isGranted,
    required this.message,
    required this.shouldShowSettings,
  });
}
