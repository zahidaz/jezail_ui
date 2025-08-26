import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

extension FileInfoFileTypeDisplay on FileInfo {
  IconData get displayIcon {
    if (isDirectory) return Icons.folder;
    if (isSymlink) return Icons.link;

    final mimeType = lookupMimeType(displayName) ?? '';
    final extension = displayName.toLowerCase();

    if (mimeType == 'application/vnd.android.package-archive') {
      return Icons.android;
    }
    
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
    if (mimeType.contains('msword') || mimeType.contains('wordprocessingml')) {
      return Icons.article;
    }
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('sheet')) {
      return Icons.table_chart;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icons.slideshow;
    }

    if (mimeType.contains('zip') ||
        mimeType.contains('x-tar') ||
        mimeType.contains('gzip') ||
        mimeType.contains('x-7z-compressed') ||
        mimeType.contains('rar')) {
      return Icons.archive;
    }

    if (mimeType == 'application/octet-stream') return Icons.memory;
    if (mimeType.contains('x-shellscript') || mimeType.contains('x-sh')) {
      return Icons.terminal;
    }
    if (mimeType.contains('x-python') || extension.endsWith('.py')) {
      return Icons.code;
    }
    if (mimeType.contains('x-javascript') ||
        mimeType == 'application/javascript' ||
        extension.endsWith('.js')) {
      return Icons.javascript;
    }
    if (extension.endsWith('.dart')) return Icons.bolt;
    if (extension.endsWith('.java')) return Icons.coffee;
    if (extension.endsWith('.c') ||
        extension.endsWith('.cpp') ||
        extension.endsWith('.h') ||
        extension.endsWith('.hpp')) {
      return Icons.developer_mode;
    }

    if (mimeType.startsWith('text/')) return Icons.description;
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;

    return Icons.insert_drive_file;
  }

  String get fileTypeDescription {
    if (isDirectory) return 'Directory';
    if (isSymlink) return 'Symbolic Link';

    final mimeType = lookupMimeType(displayName) ?? '';
    final extension = displayName.toLowerCase();

    if (mimeType == 'application/vnd.android.package-archive') {
      return 'Android Package';
    }
    
    if (mimeType == 'application/pdf') return 'PDF Document';
    if (mimeType.contains('msword') || mimeType.contains('wordprocessingml')) {
      return 'Word Document';
    }
    if (mimeType.contains('spreadsheet') ||
        mimeType.contains('excel') ||
        mimeType.contains('sheet')) {
      return 'Spreadsheet';
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return 'Presentation';
    }

    if (mimeType.contains('zip')) return 'ZIP Archive';
    if (mimeType.contains('x-tar')) return 'TAR Archive';
    if (mimeType.contains('gzip')) return 'GZIP Archive';
    if (mimeType.contains('x-7z-compressed')) return '7-Zip Archive';
    if (mimeType.contains('rar')) return 'RAR Archive';

    if (mimeType == 'application/octet-stream') return 'Binary File';
    if (mimeType.contains('x-shellscript') || mimeType.contains('x-sh')) {
      return 'Shell Script';
    }
    if (mimeType.contains('x-python') || extension.endsWith('.py')) {
      return 'Python Script';
    }
    if (mimeType.contains('x-javascript') ||
        mimeType == 'application/javascript' ||
        extension.endsWith('.js')) {
      return 'JavaScript File';
    }
    if (extension.endsWith('.dart')) return 'Dart File';
    if (extension.endsWith('.java')) return 'Java Source File';
    if (extension.endsWith('.c')) return 'C Source File';
    if (extension.endsWith('.cpp')) return 'C++ Source File';
    if (extension.endsWith('.h')) return 'C Header File';
    if (extension.endsWith('.hpp')) return 'C++ Header File';

    if (mimeType.startsWith('text/')) return 'Text File';
    if (mimeType.startsWith('image/')) return 'Image File';
    if (mimeType.startsWith('video/')) return 'Video File';
    if (mimeType.startsWith('audio/')) return 'Audio File';

    return 'File';
  }
}
