// lib/utils/file_utils.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:pdfviewer/models/document_file.dart';


class FileUtils {
  static Future<DocumentFile> createDocumentFileFromPath(String filePath) async {
    try {
      final file = File(filePath);
      
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      final fileStat = await file.stat();
      final fileName = path.basename(filePath);
      final fileNameWithoutExt = path.basenameWithoutExtension(filePath);

      
      return DocumentFile(
        path: filePath,
        name: fileNameWithoutExt,
        displayName: fileName,
        size: fileStat.size,
        lastModified: fileStat.modified,
      );
    } catch (e) {
      print('Error creating DocumentFile from path: $e');
      rethrow;
    }
  }

  // Helper method to format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Helper method to format date
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
