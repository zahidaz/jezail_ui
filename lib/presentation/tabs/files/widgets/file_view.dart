import 'package:jezail_ui/models/files/file_info.dart';
import 'package:jezail_ui/core/extensions/file_info_display_extensions.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/core/enums/file_enums.dart';
import 'package:jezail_ui/presentation/tabs/files/widgets/context_menu.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/file_ownership_dialog.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/file_permissions_dialog.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

final class FileView extends StatefulWidget {
  const FileView({
    super.key,
    required this.files,
    required this.selectedFiles,
    required this.onFileSelect,
    required this.onFileActivate,
    this.sortField,
    this.sortAscending,
    this.onSort,
    this.repository,
    this.currentPath,
    this.onChanged,
    this.onRename,
    this.onDownload,
    this.isMultiSelectMode = false,
    this.onMultiSelectModeChanged,
  });

  final List<FileInfo> files;
  final Set<FileInfo> selectedFiles;
  final void Function(FileInfo file, bool selected) onFileSelect;
  final void Function(FileInfo file) onFileActivate;
  final FileSortField? sortField;
  final bool? sortAscending;
  final void Function(FileSortField field)? onSort;
  final FileRepository? repository;
  final String? currentPath;
  final Future<void> Function()? onChanged;
  final Future<void> Function(FileInfo file)? onRename;
  final Future<void> Function(FileInfo file)? onDownload;
  final bool isMultiSelectMode;
  final VoidCallback? onMultiSelectModeChanged;

  @override
  State<FileView> createState() => _FileViewState();
}

final class _FileViewState extends State<FileView> {
  FileInfo? _contextMenuFile;

  List<FileInfo> get files => widget.files;
  Set<FileInfo> get selectedFiles => widget.selectedFiles;
  void Function(FileInfo file, bool selected) get onFileSelect => widget.onFileSelect;
  void Function(FileInfo file) get onFileActivate => widget.onFileActivate;
  FileSortField? get sortField => widget.sortField;
  bool? get sortAscending => widget.sortAscending;
  void Function(FileSortField field)? get onSort => widget.onSort;
  FileRepository? get repository => widget.repository;
  String? get currentPath => widget.currentPath;
  Future<void> Function()? get onChanged => widget.onChanged;
  Future<void> Function(FileInfo file)? get onRename => widget.onRename;
  Future<void> Function(FileInfo file)? get onDownload => widget.onDownload;
  bool get isMultiSelectMode => widget.isMultiSelectMode;
  VoidCallback? get onMultiSelectModeChanged => widget.onMultiSelectModeChanged;

  late Map<String, bool> _selectionMap;

  @override
  Widget build(BuildContext context) {
    _selectionMap = {
      for (final file in selectedFiles) file.path: true,
    };
    
    return _buildListView(context);
  }

  Widget _buildListView(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Column(
        children: [
          if (onSort != null) _buildTableHeader(theme),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemExtent: 48.0,
              cacheExtent: 1000,
              itemBuilder: (context, index) {
                final file = files[index];
                return RepaintBoundary(
                  key: ValueKey(file.path),
                  child: _buildFileListItem(context, file, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withAlpha(25))),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          if (isMultiSelectMode) 
            _buildExitMultiSelectButton(theme) 
          else 
            _buildMultiSelectToggle(theme),
          _buildHeaderCell('Name', FileSortField.name, flex: 3, icon: Icons.label),
          _buildHeaderCell('Size', FileSortField.size, icon: Icons.storage),
          _buildHeaderCell('Owner', FileSortField.permissions, icon: Icons.person),
          _buildHeaderCell('Permissions', FileSortField.permissions, icon: Icons.lock),
          _buildHeaderCell('Modified', FileSortField.modified, flex: 1, icon: Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildMultiSelectToggle(ThemeData theme) {
    return SizedBox(
      width: 40,
      child: IconButton(
        onPressed: onMultiSelectModeChanged,
        icon: Icon(
          Icons.checklist,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        tooltip: 'Enable multi-select mode',
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildExitMultiSelectButton(ThemeData theme) {
    return SizedBox(
      width: 40,
      child: IconButton(
        onPressed: onMultiSelectModeChanged,
        icon: Icon(
          Icons.close,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        tooltip: 'Exit multi-select mode',
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer.withAlpha(128),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, FileSortField field, {int flex = 1, IconData? icon}) {
    final isActive = sortField == field;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort?.call(field),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (isActive && sortAscending != null) ...[
                const SizedBox(width: 4),
                Icon(
                  sortAscending! ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileListItem(BuildContext context, FileInfo file, int index) {
    final theme = Theme.of(context);
    final isSelected = _selectionMap[file.path] == true;
    final isEvenRow = index % 2 == 0;
    final isContextMenuActive = _contextMenuFile == file;
    
    Color? backgroundColor;
    if (isSelected) {
      backgroundColor = theme.colorScheme.primaryContainer;
    } else if (!isEvenRow) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withAlpha(60);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: isContextMenuActive 
            ? Border.all(
                color: theme.colorScheme.outline.withAlpha(128),
                width: 1,
              )
            : null,
      ),
      child: _buildFileInteractiveWrapper(
        context,
        file,
        isSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (isMultiSelectMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (selected) => onFileSelect(file, selected ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
              ] else const SizedBox(width: 16),
              Icon(file.displayIcon, size: 20, color: _getFileIconColor(theme, file)),
              const SizedBox(width: 8),
              _buildFileNameCell(theme, file, flex: 3),
              _buildSizeCell(theme, file),
              _buildOwnerCell(context, theme, file),
              _buildPermissionsCell(context, theme, file),
              _buildModifiedCell(theme, file, flex: 1),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFileInteractiveWrapper(
    BuildContext context,
    FileInfo file,
    bool isCurrentlySelected, {
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () => onFileSelect(file, !isCurrentlySelected),
      onDoubleTap: () => onFileActivate(file),
      onSecondaryTapDown: (details) => _showContextMenu(context, details, file),
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  Widget _buildFileNameCell(ThemeData theme, FileInfo file, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Flexible(
            child: Text(
              file.displayName,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: file.isDirectory ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (file.isSymlink) ...[
            const SizedBox(width: 8),
            Icon(Icons.link, size: 16, color: theme.colorScheme.outline),
          ],
        ],
      ),
    );
  }

  Widget _buildSizeCell(ThemeData theme, FileInfo file) {
    return Expanded(
      child: Text(
        file.isDirectory ? '' : file.sizeFormatted,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildOwnerCell(BuildContext context, ThemeData theme, FileInfo file) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => _editOwnership(context, file),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              _formatOwnerGroup(file),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildModifiedCell(ThemeData theme, FileInfo file, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(file.lastModified, style: theme.textTheme.bodySmall),
    );
  }

  Widget _buildPermissionsCell(BuildContext context, ThemeData theme, FileInfo file) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => _editPermissions(context, file),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              file.permissions,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }




  Color? _getFileIconColor(ThemeData theme, FileInfo file) {
    if (file.isDirectory) return theme.colorScheme.primary;
    if (file.isSymlink) return theme.colorScheme.secondary;
    return theme.colorScheme.onSurface;
  }



  String _formatOwnerGroup(FileInfo file) {
    if (file.owner.isEmpty && file.group.isEmpty) return '';
    if (file.owner.isEmpty) return file.group;
    if (file.group.isEmpty) return file.owner;
    return '${file.owner}:${file.group}';
  }

  void _editOwnership(BuildContext context, FileInfo file) {
    showDialog<void>(
      context: context,
      builder: (context) => FileOwnershipDialog(
        file: file,
        onSave: (owner, group) async {
          if (repository == null || currentPath == null) return;
          try {
            final filePath = currentPath!.endsWith('/') ? '$currentPath${file.name}' : '$currentPath/${file.name}';
            if (owner != file.owner) {
              await repository!.changeOwner(filePath, owner);
            }
            if (group != file.group) {
              await repository!.changeGroup(filePath, group);
            }
            await onChanged?.call();
          } catch (e) {
            if (context.mounted) {
              context.showErrorSnackBar('Failed to update ownership: $e');
            }
          }
        },
      ),
    );
  }

  void _editPermissions(BuildContext context, FileInfo file) {
    showDialog<void>(
      context: context,
      builder: (context) => FilePermissionsDialog(
        file: file,
        onSave: (permissions) async {
          if (repository == null || currentPath == null) return;
          try {
            final filePath = currentPath!.endsWith('/') ? '$currentPath${file.name}' : '$currentPath/${file.name}';
            await repository!.changePermissions(filePath, permissions);
            await onChanged?.call();
          } catch (e) {
            if (context.mounted) {
              context.showErrorSnackBar('Failed to update permissions: $e');
            }
          }
        },
      ),
    );
  }


  void _showContextMenu(BuildContext context, TapDownDetails details, FileInfo file) {
    if (currentPath == null) return;
    
    setState(() {
      _contextMenuFile = file;
    });
    
    FileContextMenu.show(
      context,
      details,
      file,
      currentPath!,
      onDownload: onDownload,
      onRename: onRename,
    ).then((_) {
      if (mounted) {
        setState(() {
          _contextMenuFile = null;
        });
      }
    });
  }
}
