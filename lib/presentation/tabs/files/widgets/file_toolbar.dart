import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';

final class FileToolbar extends StatefulWidget {
  const FileToolbar({
    super.key,
    required this.files,
    required this.filteredFiles,
    required this.currentPath,
    required this.selectedFiles,
    required this.canNavigateUp,
    required this.onNavigateUp,
    required this.onRefresh,
    required this.onCreateFolder,
    required this.onCreateFile,
    required this.onDelete,
    required this.onUpload,
    required this.onFilterChanged,
    this.onDownload,
  });

  final List<FileInfo> files;
  final List<FileInfo> filteredFiles;
  final String currentPath;
  final Set<FileInfo> selectedFiles;
  final bool canNavigateUp;
  final VoidCallback onNavigateUp;
  final VoidCallback onRefresh;
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateFile;
  final VoidCallback onDelete;
  final VoidCallback onUpload;
  final void Function(String filter) onFilterChanged;
  final VoidCallback? onDownload;

  @override
  State<FileToolbar> createState() => _FileToolbarState();
}

final class _FileToolbarState extends State<FileToolbar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Row(
        children: [
          _buildNavigationSection(),
          const SizedBox(width: 16),
          _buildActionSection(),
          const Spacer(),
          _buildStatusSection(theme),
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: widget.canNavigateUp ? cs.primary.withAlpha(25) : cs.surfaceContainerHighest.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: widget.canNavigateUp ? widget.onNavigateUp : null,
        icon: Icon(Icons.arrow_back, size: 18, color: widget.canNavigateUp ? cs.primary : cs.onSurfaceVariant),
        tooltip: 'Navigate back',
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildActionSection() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ActionChip(
          label: const Text('Refresh', style: TextStyle(fontSize: 11)),
          onPressed: widget.onRefresh,
          avatar: const Icon(Icons.refresh, size: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          tooltip: 'Refresh (F5)',
        ),
        ActionChip(
          label: const Text('Folder', style: TextStyle(fontSize: 11)),
          onPressed: widget.onCreateFolder,
          avatar: const Icon(Icons.create_new_folder, size: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          tooltip: 'Create folder',
        ),
        ActionChip(
          label: const Text('File', style: TextStyle(fontSize: 11)),
          onPressed: widget.onCreateFile,
          avatar: const Icon(Icons.note_add, size: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          tooltip: 'Create file',
        ),
        ActionChip(
          label: const Text('Upload', style: TextStyle(fontSize: 11)),
          onPressed: widget.onUpload,
          avatar: const Icon(Icons.upload, size: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          tooltip: 'Upload files',
        ),
        if (widget.onDownload != null && widget.selectedFiles.isNotEmpty)
          ActionChip(
            label: const Text('Download', style: TextStyle(fontSize: 11)),
            onPressed: widget.onDownload,
            avatar: const Icon(Icons.download, size: 14),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            tooltip: 'Download selected files',
          ),
        if (widget.selectedFiles.isNotEmpty)
          ActionChip(
            label: Text('Delete (${widget.selectedFiles.length})', style: const TextStyle(fontSize: 11, color: Colors.red)),
            onPressed: widget.onDelete,
            avatar: const Icon(Icons.delete, size: 14, color: Colors.red),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.red.withAlpha(25),
            tooltip: 'Delete selected files',
          ),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    final totalFiles = widget.files.length;
    final filteredCount = widget.filteredFiles.length;
    final isFiltered = filteredCount != totalFiles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          isFiltered
              ? '$filteredCount of $totalFiles items'
              : '$totalFiles items',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.selectedFiles.isNotEmpty)
          Text(
            '${widget.selectedFiles.length} selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

}
