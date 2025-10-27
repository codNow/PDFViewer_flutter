import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfviewer/models/document_file.dart';
import 'package:pdfviewer/presentation/document_viewer/file_reader_screen.dart';
import 'package:pdfviewer/utils/file_utils.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(errorDetails: details);
  };
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late StreamSubscription _intentSub;
  final List<SharedMediaFile> _sharedFiles = [];

  // Add global navigator key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _initSharingIntent();
  }

  void _initSharingIntent() {
    // Listen to media sharing coming from outside the app while the app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        setState(() {
          _sharedFiles.clear();
          _sharedFiles.addAll(value);
        });
        // Use post frame callback to ensure navigation happens after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleSharedFiles();
        });
      },
      onError: (err) {
        print("getIntentDataStream error: $err");
      },
    );

    // Get the media sharing coming from outside the app while the app was closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        setState(() {
          _sharedFiles.clear();
          _sharedFiles.addAll(value);
        });
        // Use post frame callback to ensure navigation happens after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleSharedFiles();
          ReceiveSharingIntent.instance.reset();
        });
      }
    });
  }

  void _handleSharedFiles() async {
    if (_sharedFiles.isNotEmpty) {
      final sharedFile = _sharedFiles.first;
      if (sharedFile.path.toLowerCase().endsWith('.pdf')) {
        try {
          // Use the static method from FileUtils
          final documentFile = await FileUtils.createDocumentFileFromPath(
            sharedFile.path,
          );
          _openSharedPdf(documentFile);
        } catch (e) {
          print('Error handling shared PDF file: $e');
          // Show error dialog to user
          _showErrorDialog('Error opening PDF: ${e.toString()}');
        }
      }
    }
  }

  // void _openSharedPdf(DocumentFile documentFile) {
  //   // Use global navigator key instead of context
  //   final navigator = navigatorKey.currentState;
  //   if (navigator != null) {
  //     navigator.pushNamed(
  //       '/file-reader-screen', // Use named route instead of MaterialPageRoute
  //       arguments: documentFile,
  //     );
  //     // Alternative: If you prefer MaterialPageRoute
  //     // navigator.push(
  //     //   MaterialPageRoute(
  //     //     builder: (context) => FileReaderScreen(documentFile: documentFile),
  //     //   ),
  //     // );
  //   }
  // }
  void _openSharedPdf(DocumentFile documentFile) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => FileReaderScreen(documentFile: documentFile),
        ),
        (route) => false, // Remove all previous routes
      );
    }
  }

  void _showErrorDialog(String message) {
    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.context.mounted) {
      showDialog(
        context: navigator.context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('selectedTheme') ?? 'system';

    setState(() {
      switch (themeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    });
  }

  void updateTheme(String themeString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', themeString);

    setState(() {
      switch (themeString) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return ThemeProvider(
          updateTheme: updateTheme,
          child: MaterialApp(
            title: 'PDF Viewer Pro',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode,
            navigatorKey: navigatorKey, // Add navigator key here
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: child!,
              );
            },
            debugShowCheckedModeBanner: false,
            routes: AppRoutes.routes,
            initialRoute: AppRoutes.initial,
          ),
        );
      },
    );
  }
}

class ThemeProvider extends InheritedWidget {
  final Function(String) updateTheme;

  const ThemeProvider({required this.updateTheme, required Widget child})
    : super(child: child);

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(covariant ThemeProvider oldWidget) {
    return updateTheme != oldWidget.updateTheme;
  }
}
