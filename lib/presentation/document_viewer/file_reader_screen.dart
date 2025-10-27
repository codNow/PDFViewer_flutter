import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfviewer/models/document_file.dart';
import 'package:pdfviewer/services/storage_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';


class FileReaderScreen extends StatefulWidget {
  final  DocumentFile documentFile;

  const FileReaderScreen({super.key, required this.documentFile});

  @override
  State<FileReaderScreen> createState() => _FileReaderScreenState();
}

class _FileReaderScreenState extends State<FileReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isFavorite = false;
  bool _isBookmarked = false;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initializeReader();
  }

  Future<void> _initializeReader() async {
    // Mark as recently opened
    await StorageService.addRecentFile(widget.documentFile);

    // Check favorite and bookmark status
    _isFavorite = await StorageService.isFavorite(widget.documentFile.path);
    _isBookmarked = await StorageService.isBookmarked(widget.documentFile.path);

    setState(() {});
  }


  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await StorageService.removeFavorite(widget.documentFile.path);
    } else {
      await StorageService.addFavorite(widget.documentFile);
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await StorageService.removeBookmark(widget.documentFile.path);
    } else {
      await StorageService.addBookmark(widget.documentFile);
    }
    setState(() => _isBookmarked = !_isBookmarked);
  }

  void _showPageNavigator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Jump to Page',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Page number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page > 0 && page <= _totalPages) {
                        _pdfViewerController.jumpToPage(page);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'of $_totalPages',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<PopupMenuEntry<String>> _buildMenuItems() {
    return [
      const PopupMenuItem(value: 'jump', child: Text('Jump to Page')),
      const PopupMenuItem(value: 'zoom_in', child: Text('Zoom In')),
      const PopupMenuItem(value: 'zoom_out', child: Text('Zoom Out')),
      const PopupMenuItem(value: 'fit_width', child: Text('Fit Width')),
    ];
  }




  Widget _buildViewer() {
    return SfPdfViewer.file(
      File(widget.documentFile.path),
      controller: _pdfViewerController,
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentFile.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color:
                  _isBookmarked ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          if (_buildMenuItems().isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
              onSelected: (value) {
                switch (value) {
                  case 'jump':
                    _showPageNavigator();
                    break;
                  case 'zoom_in':
                    _pdfViewerController.zoomLevel += 0.25;
                    break;
                  case 'zoom_out':
                    _pdfViewerController.zoomLevel -= 0.25;
                    break;
                  case 'fit_width':
                    _pdfViewerController.zoomLevel = 1.0;
                    break;
                }
              },
              itemBuilder: (context) => _buildMenuItems(),
            ),
        ],
      ),
      body: Column(
        children: [
          // File info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/pdf_icon.png', // Your custom image path
                      width: 16,
                      height: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6), // Optional tinting
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.documentFile.formattedSize} • ${widget.documentFile.formattedDate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                // Show PDF page indicator
                if (_totalPages > 0)
                  GestureDetector(
                    onTap: _showPageNavigator,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Document Viewer
          Expanded(
            child: Container(
              color: colorScheme.surfaceContainerLowest,
              child: _buildViewer(),
            ),
          ),
        ],
      ),
    );
  }
}
