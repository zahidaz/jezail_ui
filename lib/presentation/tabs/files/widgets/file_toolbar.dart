import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/core/enums/file_enums.dart';

final class FileToolbar extends StatefulWidget {
  const FileToolbar({
    super.key,
    required this.files,
    required this.filteredFiles,
    required this.currentPath,
    required this.selectedFiles,
    required this.viewMode,
    required this.canNavigateUp,
    required this.onNavigateUp,
    required this.onRefresh,
    required this.onCreateFolder,
    required this.onCreateFile,
    required this.onDelete,
    required this.onViewModeChanged,
    required this.onUpload,
    required this.onFilterChanged,
    this.onDownload,
  });

  final List<FileInfo> files;
  final List<FileInfo> filteredFiles;
  final String currentPath;
  final Set<FileInfo> selectedFiles;
  final FileViewMode viewMode;
  final bool canNavigateUp;
  final VoidCallback onNavigateUp;
  final VoidCallback onRefresh;
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateFile;
  final VoidCallback onDelete;
  final void Function(FileViewMode mode) onViewModeChanged;
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

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildNavigationSection(),
                const SizedBox(width: 16),
                _buildActionSection(),
                const Spacer(),
                _buildStatusSection(theme),
                const SizedBox(width: 16),
                _buildViewModeSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: widget.canNavigateUp ? widget.onNavigateUp : null,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Navigate back',
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh (F5)',
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Wrap(
      spacing: 8,
      children: [
        IconButton.filledTonal(
          onPressed: widget.onCreateFolder,
          icon: const Icon(Icons.create_new_folder),
          tooltip: 'Create folder',
        ),
        IconButton.filledTonal(
          onPressed: widget.onCreateFile,
          icon: const Icon(Icons.note_add),
          tooltip: 'Create file',
        ),
        IconButton.filledTonal(
          onPressed: widget.onUpload,
          icon: const Icon(Icons.upload),
          tooltip: 'Upload files',
        ),
        if (widget.onDownload != null && widget.selectedFiles.isNotEmpty)
          IconButton.filledTonal(
            onPressed: widget.onDownload,
            icon: const Icon(Icons.download),
            tooltip: 'Download selected files',
          ),
        if (widget.selectedFiles.isNotEmpty)
          FilledButton.tonalIcon(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete),
            label: Text('Delete (${widget.selectedFiles.length})'),
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
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

  Widget _buildViewModeSelector() {
    return SegmentedButton<FileViewMode>(
      segments: const [
        ButtonSegment<FileViewMode>(
          value: FileViewMode.list,
          icon: Icon(Icons.list),
          tooltip: 'List view',
        ),
        ButtonSegment<FileViewMode>(
          value: FileViewMode.grid,
          icon: Icon(Icons.grid_view),
          tooltip: 'Grid view',
        ),
      ],
      selected: {widget.viewMode},
      onSelectionChanged: (Set<FileViewMode> newSelection) {
        if (newSelection.isNotEmpty) {
          widget.onViewModeChanged(newSelection.first);
        }
      },
      showSelectedIcon: false,
    );
  }
}
