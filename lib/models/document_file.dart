import 'package:flutter/foundation.dart';

class DocumentFile { 
  final String id = UniqueKey().toString();
  final String path;
  final String name;
  final String displayName;
  final int size;
  final DateTime lastModified;
  final bool isFavorite;
  final bool isBookmarked;
  final DateTime? lastOpened;

  DocumentFile({
    String? id,
    required this.path,
    required this.name,
    required this.displayName,
    required this.size,
    required this.lastModified,
    this.isFavorite = false,
    this.isBookmarked = false,
    this.lastOpened,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(lastModified);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
    return '${(difference.inDays / 365).floor()} years ago';
  }

  DocumentFile copyWith({
    String? id,
    String? path,
    String? name,
    String? displayName,
    int? size,
    DateTime? lastModified,
    bool? isFavorite,
    bool? isBookmarked,
    DateTime? lastOpened,
  }) {
    return DocumentFile(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      isFavorite: isFavorite ?? this.isFavorite,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'displayName': displayName,
    'size': size,
    'lastModified': lastModified.millisecondsSinceEpoch,
    'isFavorite': isFavorite,
    'isBookmarked': isBookmarked,
    'lastOpened': lastOpened?.millisecondsSinceEpoch,
  };

  factory DocumentFile.fromJson(Map<String, dynamic> json) => DocumentFile(
    id: json['id'],
    path: json['path'],
    name: json['name'],
    displayName: json['displayName'],
    size: json['size'],
    lastModified: DateTime.fromMillisecondsSinceEpoch(json['lastModified']),
    isFavorite: json['isFavorite'] ?? false,
    isBookmarked: json['isBookmarked'] ?? false,
    lastOpened: json['lastOpened'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['lastOpened'])
        : null,
  );
}

