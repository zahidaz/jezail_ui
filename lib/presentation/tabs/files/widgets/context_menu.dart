import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/models/files/file_info.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

final class FileContextMenu {
  const FileContextMenu._();

  static Future<void> show(
    BuildContext context,
    TapDownDetails details,
    FileInfo file,
    String currentPath, {
    Future<void> Function(FileInfo file)? onDownload,
    Future<void> Function(FileInfo file)? onRename,
  }) async {
    await showMenu<_MenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.copyName,
          child: const Row(
            children: [
              Icon(Icons.drive_file_rename_outline, size: 16),
              SizedBox(width: 8),
              Text('Copy Name'),
            ],
          ),
        ),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.copyPath,
          child: const Row(
            children: [
              Icon(Icons.folder_open, size: 16),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.copyPermissions,
          child: const Row(
            children: [
              Icon(Icons.security, size: 16),
              SizedBox(width: 8),
              Text('Copy Permissions'),
            ],
          ),
        ),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.download,
          child: const Row(
            children: [
              Icon(Icons.download, size: 16),
              SizedBox(width: 8),
              Text('Download'),
            ],
          ),
        ),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.rename,
          child: const Row(
            children: [
              Icon(Icons.edit, size: 16),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
      ],
    ).then((action) {
      if (action != null && context.mounted) {
        _handleMenuAction(
          context,
          action,
          file,
          currentPath,
          onDownload: onDownload,
          onRename: onRename,
        );
      }
    });
  }

  static void _handleMenuAction(
    BuildContext context,
    _MenuAction action,
    FileInfo file,
    String currentPath, {
    Future<void> Function(FileInfo file)? onDownload,
    Future<void> Function(FileInfo file)? onRename,
  }) {
    switch (action) {
      case _MenuAction.copyName:
        _copyToClipboard(context, file.displayName, 'File name');
        break;
      case _MenuAction.copyPath:
        _copyToClipboard(context, file.path, 'Full path');
        break;
      case _MenuAction.copyPermissions:
        _copyToClipboard(context, file.permissions, 'Permissions');
        break;
      case _MenuAction.download:
        onDownload?.call(file);
        break;
      case _MenuAction.rename:
        onRename?.call(file);
        break;
    }
  }

  static Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String label,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        context.showInfoSnackBar('$label copied to clipboard');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Failed to copy $label: $e');
      }
    }
  }
}

enum _MenuAction {
  copyName,
  copyPath,
  copyPermissions,
  download,
  rename,
}
