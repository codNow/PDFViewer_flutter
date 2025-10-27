import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfviewer/main.dart';
import 'package:pdfviewer/services/pdf_service.dart';
import 'package:pdfviewer/widgets/asset_icon_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);


  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _permissionGranted = false;
  bool _isScanning = false;
  bool _showPermissionDialog = false;
  double _scanProgress = 0.0;
  String _scanningStatus = 'Initializing...';
  int _filesFound = 0;


  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkPermissionAndProceed();
  }


  void _setupAnimations() {
    // Logo scale animation
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );


    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));


    // Fade animation for transition
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );


    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));


    // Start logo animation
    _logoAnimationController.forward();
  }


  Future<void> _checkPermissionAndProceed() async {
    // Wait for logo animation to complete
    await _logoAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if permission is already granted
    final hasPermission = await _checkStoragePermission();
    
    if (hasPermission) {
      setState(() => _permissionGranted = true);
      await _startFileScanning();
    } else {
      // Show permission dialog
      setState(() => _showPermissionDialog = true);
    }
  }


  Future<bool> _checkStoragePermission() async {
    final manage = Permission.manageExternalStorage;
    final manageStatus = await manage.status;
    return manageStatus.isGranted;
  }


  Future<void> _requestPermission() async {
    setState(() {
      _showPermissionDialog = false;
      _scanningStatus = 'Requesting permission...';
    });
    
    final hasPermission = await FileService.requestStoragePermission();
    
    if (hasPermission) {
      setState(() => _permissionGranted = true);
      await _startFileScanning();
    } else {
      // Permission denied, show dialog again
      setState(() => _showPermissionDialog = true);
    }
  }


  Future<void> _startFileScanning() async {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanningStatus = 'Starting scan...';
      _filesFound = 0;
    });


    // Simulate progress updates during scanning
    _simulateProgress();
    
    try {
      // Perform the actual file scan
      final files = await FileService.scanForFiles(forceRefresh: true);
      
      setState(() {
        _filesFound = files.length;
        _scanProgress = 1.0;
        _scanningStatus = 'Scan complete!';
      });
      
      // Wait a moment to show completion
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Navigate to main screen
      await _navigateToHome();
      
    } catch (e) {
      setState(() {
        _scanningStatus = 'Error scanning files';
      });
      print('Error during file scan: $e');
      
      // Still navigate after error
      await Future.delayed(const Duration(seconds: 2));
      await _navigateToHome();
    }
  }


  void _simulateProgress() {
    // Simulate progress while scanning
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _scanProgress < 0.9) {
        setState(() {
          _scanProgress += 0.1;
          if (_scanProgress < 0.3) {
            _scanningStatus = 'Scanning storage...';
          } else if (_scanProgress < 0.6) {
            _scanningStatus = 'Finding documents...';
          } else {
            _scanningStatus = 'Processing files...';
          }
        });
        _simulateProgress();
      }
    });
  }


  Future<void> _navigateToHome() async {
    // Start fade out animation
    await _fadeController.forward();
    
    // Navigate to home screen and replace current route
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/file-list-dashboard');
    }
  }


  @override
  void dispose() {
    _logoAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo section
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _logoScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // App logo
                                      Center(
                                        child: AssetIconWidget(
                                          iconName: 'logo',
                                          fileExtension: 'png',
                                          size: 24.w,
                                        ),
                                      ),
                                      SizedBox(height: 3.h),
                                      // App name
                                      Text(
                                        'PDFViewer',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 1.h),
                                      // App tagline
                                      Text(
                                        'Your Mobile Document Hub',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),


                        // Loading section with progress bar
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isScanning) ...[
                                // Horizontal progress bar
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value: _scanProgress,
                                          minHeight: 8,
                                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Colors.lightBlueAccent,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      // Status message
                                      Text(
                                        _scanningStatus,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      // Files found count
                                      Text(
                                        'Found $_filesFound documents',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (!_showPermissionDialog) ...[
                                // Initial loading indicator
                                SizedBox(
                                  width: 8.w,
                                  height: 8.w,
                                  child: const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.lightBlueAccent),
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _scanningStatus,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),


                        // Bottom section with version info
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Column(
                            children: [
                              Text(
                                'Version 1.0.0',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                '© 2025 PDFViewer',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Permission dialog overlay
                    if (_showPermissionDialog)
                      _buildPermissionDialog(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildPermissionDialog() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                Icons.folder_open,
                size: 15.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 3.h),
              
              // Title
              Text(
                'Storage Access Required',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              
              // Description
              Text(
                'To scan and display your documents, DocViewer needs access to all files on your device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              
              // Instructions
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps to enable:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildInstructionStep('1', 'Tap "Go to Settings" below'),
                    _buildInstructionStep('2', 'Enable "All files access"'),
                    _buildInstructionStep('3', 'Return to the app'),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _requestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go to Settings'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 0.3.h),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}