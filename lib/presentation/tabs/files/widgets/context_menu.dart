import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/models/files/file_info.dart';

final class FileContextMenu extends StatelessWidget {
  const FileContextMenu({
    super.key,
    required this.file,
    required this.currentPath,
    this.onDownload,
    this.onRename,
    this.onShowProperties,
  });

  final FileInfo file;
  final String currentPath;
  final Future<void> Function(FileInfo file)? onDownload;
  final Future<void> Function(FileInfo file)? onRename;
  final void Function(FileInfo file)? onShowProperties;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  static Future<void> show(
    BuildContext context,
    TapDownDetails details,
    FileInfo file,
    String currentPath, {
    Future<void> Function(FileInfo file)? onDownload,
    Future<void> Function(FileInfo file)? onRename,
    void Function(FileInfo file)? onShowProperties,
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
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.properties,
          child: const Row(
            children: [
              Icon(Icons.info, size: 16),
              SizedBox(width: 8),
              Text('Properties'),
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
          onShowProperties: onShowProperties,
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
    void Function(FileInfo file)? onShowProperties,
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
      case _MenuAction.properties:
        onShowProperties?.call(file);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy $label: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
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
  properties,
}
