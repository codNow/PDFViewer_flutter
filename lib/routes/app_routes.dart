import 'package:flutter/material.dart';
import 'package:pdfviewer/presentation/document_viewer/file_reader_screen.dart';
import 'package:pdfviewer/presentation/library_screen/library_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/settings_and_preferences/settings_and_preferences.dart';
import '../models/document_file.dart';

class AppRoutes {
  static const String initial = '/';
  static const String fileReader = '/file-reader-screen';
  static const String splash = '/splash-screen';
  static const String fileListDashboard = '/file-list-dashboard';
  static const String settingsAndPreferences = '/settings-and-preferences';
  static const String libraryScreen = '/library-screen';


  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    fileReader: (context) {
      final documentFile =
          ModalRoute.of(context)!.settings.arguments as DocumentFile;
      return FileReaderScreen(documentFile: documentFile);
    },
    splash: (context) => const SplashScreen(),
    fileListDashboard: (context) => const FileListDashboard(),
    settingsAndPreferences: (context) => const SettingsAndPreferences(),
    libraryScreen: (context) => LibraryScreen(
      onFileOpen: (file) {
        // TODO: Implement file open logic
      },
      onImportTap: () {
        // TODO: Implement import tap logic
      },
    ),
    // TODO: Add your other routes here
  };
}
