import 'package:jezail_ui/models/files/file_info.dart';

extension FileInfoDisplay on FileInfo {
  String get formattedSize {
    final bytes = size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get typeDisplay {
    if (isDirectory) return 'Folder';
    if (isSymlink) return 'Symlink';
    
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return 'Image';
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return 'Video';
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return 'Audio';
      case 'txt':
      case 'md':
      case 'log':
        return 'Text';
      case 'apk':
        return 'APK';
      default:
        return 'File';
    }
  }
}