import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdfviewer/main.dart';
import 'package:pdfviewer/presentation/settings_and_preferences/widgets/file_stats-widget.dart';
import 'package:pdfviewer/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import './widgets/about_section_widget.dart';
import './widgets/display_settings_widget.dart';
import './widgets/reset_options_widget.dart';

class SettingsAndPreferences extends StatefulWidget {
  final VoidCallbackAction? onThemeChanged;
  const SettingsAndPreferences({Key? key, this.onThemeChanged})
    : super(key: key);

  @override
  State<SettingsAndPreferences> createState() => _SettingsAndPreferencesState();
}

class _SettingsAndPreferencesState extends State<SettingsAndPreferences> {
  // Add a unique key for the entire widget tree
  Key _widgetKey = UniqueKey();

  // Display settings
  String _currentTheme = 'system';
  double _textSize = 14.0;
  double _defaultZoom = 1.0;

  // Cloud services

  // Security settings
  // bool _biometricEnabled = false;
  // String _autoLockTimer = '5 minutes';
  // bool _hasPermission = false;

  // App info
  final String _appVersion = '1.1.0';
  final String _storagePermissionStatus = 'Granted';

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  // Mock cloud accounts data
  // final List<Map<String, dynamic>> _connectedAccounts = [
  //   {'service': 'Google Drive', 'email': 'user@gmail.com', 'connected': true},
  //   {'service': 'OneDrive', 'email': 'user@outlook.com', 'connected': true},
  //   {'service': 'Dropbox', 'email': '', 'connected': false},
  // ];

  Future<void> _loadCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('selectedTheme') ?? 'system';
    });
  }

  void _onThemeChanged(String theme) {
    // Get the theme provider from context
    final themeProvider = ThemeProvider.of(context);

    if (themeProvider != null) {
      // Call the updateTheme function
      themeProvider.updateTheme(theme);

      setState(() {
        _currentTheme = theme;
      });

      _showToast('Theme changed to ${theme.capitalize()}');

      // Safe calling method
    }
  }

  void _onTextSizeChanged(double size) {
    setState(() {
      _textSize = size;
    });
  }

  void _onZoomChanged(double zoom) {
    setState(() {
      _defaultZoom = zoom;
    });
  }

  // Cloud services callbacks
  // void _onManageAccount(String serviceName) {
  //   final account = _connectedAccounts.firstWhere(
  //     (acc) => acc['service'] == serviceName,
  //   );

  //   if (account['connected'] as bool) {
  //     _showAccountManagementDialog(serviceName, account['email'] as String);
  //   } else {
  //     _connectToService(serviceName);
  //   }
  // }

  // void _onSyncFrequencyChanged(String frequency) {
  //   setState(() {
  //     _syncFrequency = frequency;
  //   });
  //   _showToast('Sync frequency set to $frequency');
  // }

  // Security settings callbacks
  // void _onBiometricChanged(bool value) {
  //   setState(() {
  //     _biometricEnabled = value;
  //   });
  //   _showToast('Biometric authentication ${value ? 'enabled' : 'disabled'}');
  // }

  // void _onAutoLockChanged(String timer) {
  //   setState(() {
  //     _autoLockTimer = timer;
  //   });
  //   _showToast('Auto-lock timer set to $timer');
  // }

  // About section callbacks
  void _onPrivacyPressed() {
    _showPrivacyPolicy(context);
  }

  void _onTermsPressed() {
    _showTermsOfService(context);
  }

  // Reset options callbacks
  void _onClearSearchHistory() async{
    _showConfirmationDialog(
      'Clear Search History',
      'This will permanently delete all your search history. Continue?',
      () {
        _showToast('Search history cleared');
      },
    );
  }

  void _onResetPreferences() {
    _showResetDialog(
      'Reset Preferences',
      'This will reset all settings to their default values. Continue?',
      () {
        _resetAllPreferences();
        _showToast('Preferences reset to defaults');
      },
    );
  }

  // void _disconnectService(String serviceName) {
  //   final accountIndex = _connectedAccounts.indexWhere(
  //     (acc) => acc['service'] == serviceName,
  //   );

  //   if (accountIndex != -1) {
  //     setState(() {
  //       _connectedAccounts[accountIndex]['connected'] = false;
  //       _connectedAccounts[accountIndex]['email'] = '';
  //     });
  //     _showToast('Disconnected from $serviceName');
  //   }
  // }

  // void _connectToService(String serviceName) {
  //   // Implementation for connecting to service
  // }

  void _resetAllPreferences() {
    setState(() {
      _currentTheme = 'system';
      _textSize = 14.0;
      _defaultZoom = 1.0;
      _widgetKey = UniqueKey(); // Force rebuild after reset
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap entire scaffold with the unique key and theme-aware container
    return Theme(
      key: _widgetKey, // Apply the unique key here
      data: Theme.of(context),
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(context),
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Text(
        'Settings & Preferences',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            DisplaySettingsWidget(
              currentTheme: _currentTheme,
              textSize: _textSize,
              defaultZoom: _defaultZoom,
              onThemeChanged: _onThemeChanged,
              onTextSizeChanged: _onTextSizeChanged,
              onZoomChanged: _onZoomChanged,
            ),
            _buildStatsSection(),
            // CloudServicesWidget(
            //   connectedAccounts: _connectedAccounts,
            //   syncFrequency: _syncFrequency,
            //   onManageAccount: _onManageAccount,
            //   onSyncFrequencyChanged: _onSyncFrequencyChanged,
            // ),
            // SecuritySettingsWidget(
            //   biometricEnabled: _biometricEnabled,
            //   autoLockTimer: _autoLockTimer,
            //   onBiometricChanged: _onBiometricChanged,
            //   onAutoLockChanged: _onAutoLockChanged,
            // ),
            AboutSectionWidget(
              appVersion: _appVersion,
              storagePermissionStatus: _storagePermissionStatus,
              onPrivacyPressed: _onPrivacyPressed,
              onTermsPressed: _onTermsPressed,
            ),
            ResetOptionsWidget(
              onClearSearchHistory: _onClearSearchHistory,
              onResetPreferences: _onResetPreferences,
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        // Use theme card color instead of hardcoded
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
                  iconName: 'storage',
                  // Use theme primary color
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Storage',
                  // Use theme text styles
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),

          // Use FutureBuilder to load stats asynchronously
          FutureBuilder<Map<String, dynamic>>(
            future: _loadStatsData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingStats();
              }

              if (snapshot.hasError) {
                return _buildErrorStats(snapshot.error.toString());
              }

              if (!snapshot.hasData) {
                return _buildEmptyStats();
              }

              final stats = snapshot.data!;
              return _buildStatsContent(stats);
            },
          ),
        ],
      ),
    );
  }

  // Method to load all the stats data
  Future<Map<String, dynamic>> _loadStatsData() async {
    try {
      final allFiles = await StorageService.getAllPdfFilesCached();
      final recentFiles = await StorageService.getRecentFiles();
      final bookmarks = await StorageService.getBookmarks();

      // Calculate storage used (convert bytes to GB)
      double storageUsed = 0.0;
      for (final file in allFiles) {
        storageUsed += file.size;
      }
      storageUsed = storageUsed / (1024 * 1024 * 1024); // Convert to GB

      // You can get total storage from device info or set a default
      double totalStorage = 64.0; // Default or get from device

      return {
        'totalDocuments': allFiles.length,
        'recentFiles': recentFiles.length,
        'bookmarks': bookmarks.length,
        'storageUsed': storageUsed,
        'totalStorage': totalStorage,
        'allFiles': allFiles,
      };
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  // Build the actual stats content when data is loaded
  Widget _buildStatsContent(Map<String, dynamic> stats) {
    return Container(
      margin: EdgeInsets.only(left: 2.w, right: 2.w, bottom: 2.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FileStatsCard(
                  title: 'Documents',
                  value: stats['totalDocuments'].toString(),
                  icon: Icons.description,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: FileStatsCard(
                  title: 'Recent Files',
                  value: stats['recentFiles'].toString(),
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          FileStatsCard(
            title: 'Storage Used',
            value: '${stats['storageUsed'].toStringAsFixed(1)} GB',
            subtitle: 'of ${stats['totalStorage'].toStringAsFixed(1)} GB',
            icon: Icons.storage,
            color: Colors.green,
            progress: stats['storageUsed'] / stats['totalStorage'],
          ),
        ],
      ),
    );
  }

  // Loading state while fetching data
  Widget _buildLoadingStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            SizedBox(width: 3.w),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
        SizedBox(height: 2.h),
        _buildLoadingCard(),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  // Error state if something goes wrong
  Widget _buildErrorStats(String error) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 24),
            SizedBox(height: 8),
            Text(
              'Failed to load stats',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state if no data
  Widget _buildEmptyStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FileStatsCard(
                title: 'Documents',
                value: '0',
                icon: Icons.description,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: FileStatsCard(
                title: 'Recent Files',
                value: '0',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        FileStatsCard(
          title: 'Storage Used',
          value: '0.0 GB',
          subtitle: 'of 0.0 GB',
          icon: Icons.storage,
          color: Colors.green,
          progress: 0.0,
        ),
      ],
    );
  }

  void _showConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }
  void _showResetDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  // void _showAccountManagementDialog(String serviceName, String email) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       final theme = Theme.of(context);
  //       return AlertDialog(
  //         backgroundColor: theme.dialogBackgroundColor,
  //         title: Text(
  //           'Manage $serviceName',
  //           style: theme.textTheme.titleMedium?.copyWith(
  //             color: theme.colorScheme.onSurface,
  //           ),
  //         ),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               'Connected as: $email',
  //               style: theme.textTheme.bodyMedium?.copyWith(
  //                 color: theme.colorScheme.onSurface,
  //               ),
  //             ),
  //             SizedBox(height: 2.h),
  //             Text(
  //               'What would you like to do?',
  //               style: theme.textTheme.bodySmall?.copyWith(
  //                 color: theme.colorScheme.onSurfaceVariant,
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text(
  //               'Cancel',
  //               style: TextStyle(color: theme.colorScheme.onSurface),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               _disconnectService(serviceName);
  //             },
  //             child: Text(
  //               'Disconnect',
  //               style: TextStyle(color: theme.colorScheme.error),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showToast(String message) {
    final theme = Theme.of(context);
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: theme.colorScheme.inverseSurface,
      textColor: theme.colorScheme.onInverseSurface,
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Privacy Policy'),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 3.h),
                _buildPrivacyPolicyContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '1. Information We Collect'),
        _buildSectionText(
          context,
          'PDFViewer processes document files locally on your device. We do not collect, store, or transmit any personal information or document content to external servers.',
        ),

        SizedBox(height: 2.h),
        _buildSectionTitle(context, '2. Local Data Processing'),
        _buildSectionText(
          context,
          'All document scanning, viewing, and processing occurs entirely on your device. Your files remain private and are never uploaded to any server.',
        ),

        SizedBox(height: 2.h),
        _buildSectionTitle(context, '3. Permissions'),
        _buildSectionText(
          context,
          'This app requires storage permissions to access and display your document files. These permissions are used solely for local file operations.',
        ),

        SizedBox(height: 2.h),
        _buildSectionTitle(context, '4. Contact Information'),
        _buildSectionText(
          context,
          'If you have questions about this Privacy Policy, please contact us at support@pdfviewer.app',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSectionText(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Terms of Service'),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms of Service',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Last updated: ${DateTime.now().toString().split(' ')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 3.h),
                _buildTermsContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '1. Acceptance of Terms'),
        _buildSectionText(
          context,
          'By using PDFViewer, you agree to be bound by these Terms of Service.',
        ),

        SizedBox(height: 2.h),
        _buildSectionTitle(context, '2. Use of Service'),
        _buildSectionText(
          context,
          'PDFViewer is provided for document viewing and management purposes. You may use this app to view, organize, and manage your document files.',
        ),

        SizedBox(height: 2.h),
        _buildSectionTitle(context, '3. User Responsibilities'),
        _buildSectionText(
          context,
          'You are responsible for ensuring you have appropriate rights to access and view documents on your device.',
        ),

        SizedBox(height: 2.h),
        _buildSectionTitle(context, '4. Limitation of Liability'),
        _buildSectionText(
          context,
          'PDFViewer is provided "as is" without any warranties. We are not liable for any data loss or damages.',
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
