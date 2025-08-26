import 'package:jezail_ui/models/files/file_info.dart';
import 'package:jezail_ui/core/extensions/file_info_display_extensions.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/core/enums/file_enums.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/properties/file_properties_dialog.dart';
import 'package:jezail_ui/presentation/tabs/files/widgets/context_menu.dart';

final class FileView extends StatelessWidget {
  const FileView({
    super.key,
    required this.files,
    required this.selectedFiles,
    required this.onFileSelect,
    required this.onFileActivate,
    required this.viewMode,
    this.sortField,
    this.sortAscending,
    this.onSort,
    this.repository,
    this.currentPath,
    this.onChanged,
    this.onRename,
    this.onDownload,
  });

  final List<FileInfo> files;
  final Set<FileInfo> selectedFiles;
  final void Function(FileInfo file, bool selected) onFileSelect;
  final void Function(FileInfo file) onFileActivate;
  final FileViewMode viewMode;
  final FileSortField? sortField;
  final bool? sortAscending;
  final void Function(FileSortField field)? onSort;
  final FileRepository? repository;
  final String? currentPath;
  final VoidCallback? onChanged;
  final Future<void> Function(FileInfo file)? onRename;
  final Future<void> Function(FileInfo file)? onDownload;

  @override
  Widget build(BuildContext context) {
    return switch (viewMode) {
      FileViewMode.list => _buildListView(context),
      FileViewMode.grid => _buildGridView(context),
    };
  }

  Widget _buildListView(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          if (onSort != null) _buildTableHeader(theme),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) => _buildFileListItem(context, files[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) => _buildFileGridItem(context, files[index]),
        );
      },
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          _buildHeaderCell('Name', FileSortField.name, flex: 3),
          _buildHeaderCell('Size', FileSortField.size),
          _buildHeaderCell('Type', FileSortField.type),
          _buildHeaderCell('Modified', FileSortField.modified, flex: 2),
          _buildHeaderCell('Permissions', FileSortField.permissions),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, FileSortField field, {int flex = 1}) {
    final isActive = sortField == field;
    
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort?.call(field),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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

  Widget _buildFileListItem(BuildContext context, FileInfo file) {
    final theme = Theme.of(context);
    final isSelected = selectedFiles.contains(file);
    
    return Material(
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: _buildFileInteractiveWrapper(
        context,
        file,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (selected) => onFileSelect(file, selected ?? false),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Icon(file.displayIcon, size: 20, color: _getFileIconColor(theme, file)),
              const SizedBox(width: 8),
              _buildFileNameCell(theme, file, flex: 3),
              _buildSizeCell(theme, file),
              _buildTypeCell(theme, file),
              _buildModifiedCell(theme, file, flex: 2),
              _buildPermissionsCell(context, theme, file),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileGridItem(BuildContext context, FileInfo file) {
    final theme = Theme.of(context);
    final isSelected = selectedFiles.contains(file);
    
    return Card(
      elevation: isSelected ? 4.0 : 1.0,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: _buildFileInteractiveWrapper(
        context,
        file,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: _buildGridIcon(theme, file, isSelected),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildGridFileName(theme, file)),
              if (file.isSymlink) ...[
                const SizedBox(height: 4),
                _buildSymlinkIndicator(theme),
              ],
              if (isSelected) ...[
                const SizedBox(height: 4),
                _buildSelectionIndicator(theme),
              ],
              if (_hasPropertiesAccess()) ...[
                const SizedBox(height: 4),
                _buildInfoButton(context, file),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInteractiveWrapper(
    BuildContext context,
    FileInfo file, {
    required Widget child,
  }) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == 2) {
          _showContextMenu(context, TapDownDetails(globalPosition: event.position), file);
        }
      },
      child: GestureDetector(
        onTap: () => onFileSelect(file, !selectedFiles.contains(file)),
        onDoubleTap: () => onFileActivate(file),
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
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

  Widget _buildTypeCell(ThemeData theme, FileInfo file) {
    return Expanded(
      child: Chip(
        label: Text(file.fileTypeDescription, style: theme.textTheme.labelSmall),
        visualDensity: VisualDensity.compact,
        backgroundColor: _getTypeColor(theme, file),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              file.permissions,
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          if (_hasPropertiesAccess())
            IconButton(
              icon: const Icon(Icons.info, size: 16),
              onPressed: () => _showPropertiesDialog(context, file),
              tooltip: 'Properties',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildGridIcon(ThemeData theme, FileInfo file, bool isSelected) {
    return Badge(
      isLabelVisible: !file.isDirectory && file.size > 1024 * 1024,
      label: Text(_getSizeBadge(file)),
      child: Icon(
        file.displayIcon,
        size: 48,
        color: _getFileIconColor(theme, file),
      ),
    );
  }

  Widget _buildGridFileName(ThemeData theme, FileInfo file) {
    return Text(
      file.displayName,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: file.isDirectory ? FontWeight.w500 : FontWeight.normal,
        height: 1.2,
      ),
    );
  }

  Widget _buildSymlinkIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 12, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 2),
          Text(
            'Link',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, size: 12, color: theme.colorScheme.onPrimary),
    );
  }

  Widget _buildInfoButton(BuildContext context, FileInfo file) {
    return SizedBox(
      width: 32,
      height: 20,
      child: IconButton(
        icon: const Icon(Icons.info, size: 12),
        onPressed: () => _showPropertiesDialog(context, file),
        tooltip: 'Properties',
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }

  int _calculateCrossAxisCount(double width) {
    const minCardWidth = 120.0;
    final count = (width - 32.0) ~/ (minCardWidth + 16.0);
    return (count < 2) ? 2 : (count > 8) ? 8 : count;
  }

  Color? _getFileIconColor(ThemeData theme, FileInfo file) {
    if (file.isDirectory) return theme.colorScheme.primary;
    if (file.isSymlink) return theme.colorScheme.secondary;
    return theme.colorScheme.onSurface;
  }

  Color? _getTypeColor(ThemeData theme, FileInfo file) {
    if (file.isDirectory) return theme.colorScheme.primaryContainer;
    if (file.isSymlink) return theme.colorScheme.secondaryContainer;
    return theme.colorScheme.surfaceContainerHighest;
  }

  String _getSizeBadge(FileInfo file) {
    if (file.size > 1024 * 1024 * 1024) return 'GB';
    if (file.size > 1024 * 1024) return 'MB';
    return '';
  }

  bool _hasPropertiesAccess() => repository != null && currentPath != null;

  void _showPropertiesDialog(BuildContext context, FileInfo file) {
    if (!_hasPropertiesAccess() || onChanged == null) return;
    
    showDialog<void>(
      context: context,
      builder: (context) => FilePropertiesDialog(
        file: file,
        repository: repository!,
        currentPath: currentPath!,
        onChanged: onChanged!,
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details, FileInfo file) {
    if (currentPath == null) return;
    
    FileContextMenu.show(
      context,
      details,
      file,
      currentPath!,
      onDownload: onDownload,
      onRename: onRename,
      onShowProperties: (file) => _showPropertiesDialog(context, file),
    );
  }
}
