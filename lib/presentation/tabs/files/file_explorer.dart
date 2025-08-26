import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/presentation/controllers/file_explorer_controller.dart';
import 'package:jezail_ui/models/files/file_explorer_view_state.dart';
import 'package:jezail_ui/models/files/file_operation_result.dart';
import 'package:jezail_ui/presentation/tabs/files/widgets/file_toolbar.dart';
import 'package:jezail_ui/presentation/tabs/files/widgets/file_view.dart';
import 'package:jezail_ui/presentation/tabs/files/widgets/path_navigator.dart';
import 'package:jezail_ui/presentation/tabs/files/widgets/quick_access.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/file_create_dialog.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/file_upload_dialog.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/file_preview_dialog.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/file_edit_dialog.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/file_rename_dialog.dart';

final class FileExplorer extends StatefulWidget {
  const FileExplorer({
    super.key, 
    required this.repository,
    this.onPathChanged,
  });

  final FileRepository repository;
  final void Function(String path)? onPathChanged;

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

final class _FileExplorerState extends State<FileExplorer> {
  late final FileExplorerController _controller;
  final TextEditingController _pathController = TextEditingController();
  String _filterQuery = '';
  List<FileInfo> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    _controller = FileExplorerController(widget.repository);
    _controller.addListener(_onStateChanged);
    _pathController.text = _controller.value.currentPath;
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final currentPath = _controller.value.currentPath;
    _pathController.text = currentPath;
    _updateFilteredFiles();
    widget.onPathChanged?.call(currentPath);
  }

  void navigateToPath(String path) {
    _controller.navigateToPath(path);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FileExplorerViewState>(
      valueListenable: _controller,
      builder: (context, state, child) {
        return Column(
          children: [
            FileToolbar(
              files: state.files,
              filteredFiles: _filteredFiles.isNotEmpty
                  ? _filteredFiles
                  : state.files,
              currentPath: state.currentPath,
              selectedFiles: state.selectedFiles,
              viewMode: state.viewMode,
              canNavigateUp: state.canNavigateUp,
              onNavigateUp: _controller.navigateUp,
              onRefresh: _controller.refreshCurrentDirectory,
              onCreateFolder: _showCreateFolderDialog,
              onCreateFile: _showCreateFileDialog,
              onDelete: _deleteSelectedFiles,
              onViewModeChanged: (mode) => setState(() {
                _controller.value = _controller.value.copyWith(viewMode: mode);
              }),
              onUpload: _showUploadDialog,
              onFilterChanged: _onFilterChanged,
              onDownload: _downloadSelectedFiles,
            ),
            PathNavigator(
              currentPath: state.currentPath,
              pathController: _pathController,
              onNavigate: _controller.navigateToPath,
              onFilterChanged: _onFilterChanged,
            ),
            QuickAccess(
              currentPath: state.currentPath,
              onNavigate: _controller.navigateToPath,
            ),
            Expanded(child: _buildFileView(state)),
          ],
        );
      },
    );
  }

  Widget _buildFileView(FileExplorerViewState state) {
    return state.filesResult.when<Widget>(
      success: (files) => _buildFileContent(state),
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading directory...'),
          ],
        ),
      ),
      error: (message, exception) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading directory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _controller.refreshCurrentDirectory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(FileExplorerViewState state) {
    final displayFiles = _filteredFiles.isNotEmpty
        ? _filteredFiles
        : state.files;

    if (state.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Directory is empty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (displayFiles.isEmpty && _filterQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No files match filter',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return FileView(
      files: displayFiles,
      selectedFiles: state.selectedFiles,
      viewMode: state.viewMode,
      sortField: state.sortField,
      sortAscending: state.sortAscending,
      onFileSelect: _onFileSelect,
      onFileActivate: _onFileActivate,
      onSort: _controller.setSortField,
      repository: widget.repository,
      currentPath: state.currentPath,
      onChanged: _controller.refreshCurrentDirectory,
      onRename: _onRenameFile,
      onDownload: _downloadFile,
    );
  }

  void _onFileSelect(FileInfo file, bool selected) {
    if (selected) {
      _controller.toggleFileSelection(file);
    } else {
      _controller.clearSelection();
    }
  }

  void _onFileActivate(FileInfo file) {
    if (file.isDirectory) {
      _controller.navigateToChild(file.displayName);
    } else {
      _showFilePreview(file);
    }
  }

  void _onFilterChanged(String query) {
    setState(() {
      _filterQuery = query;
      _updateFilteredFiles();
    });
  }

  void _updateFilteredFiles() {
    final files = _controller.value.files;
    if (_filterQuery.isEmpty) {
      _filteredFiles = files;
    } else {
      final query = _filterQuery.toLowerCase();
      _filteredFiles = files.where((file) {
        return file.displayName.toLowerCase().contains(query) ||
            file.permissions.contains(query) ||
            file.owner.toLowerCase().contains(query) ||
            file.group.toLowerCase().contains(query) ||
            file.type.name.toLowerCase().contains(query);
      }).toList();
    }
  }

  void _showCreateFolderDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => FileCreateDialog(
        isDirectory: true,
        repository: widget.repository,
        currentPath: _controller.value.currentPath,
        onCreated: _controller.refreshCurrentDirectory,
      ),
    );
  }

  void _showCreateFileDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => FileCreateDialog(
        isDirectory: false,
        repository: widget.repository,
        currentPath: _controller.value.currentPath,
        onCreated: _controller.refreshCurrentDirectory,
      ),
    );
  }

  void _showUploadDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => FileUploadDialog(
        repository: widget.repository,
        currentPath: _controller.value.currentPath,
        onUploaded: _controller.refreshCurrentDirectory,
      ),
    );
  }

  void _showFilePreview(FileInfo file) {
    showDialog<void>(
      context: context,
      builder: (context) => FilePreviewDialog(
        file: file,
        repository: widget.repository,
        currentPath: _controller.value.currentPath,
        onEdit: () => _showFileEdit(file),
        onDownload: () => _downloadFile(file),
        onChanged: _controller.refreshCurrentDirectory,
      ),
    );
  }

  void _showFileEdit(FileInfo file) {
    showDialog<void>(
      context: context,
      builder: (context) => FileEditDialog(
        file: file,
        repository: widget.repository,
        currentPath: _controller.value.currentPath,
      ),
    );
  }

  Future<void> _downloadFile(FileInfo file) async {
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(content: Text('Downloading ${file.displayName}...')),
    );

    final result = await _controller.downloadFile(file);

    if (!mounted) return;

    result.when(
      success: (data) {
        messenger.showSnackBar(
          SnackBar(content: Text('Downloaded ${file.displayName}')),
        );
      },
      loading: () {},
      error: (message, exception) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Download failed: $message'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      },
    );
  }

  Future<void> _downloadSelectedFiles() async {
    final files = _controller.value.selectedFiles;
    if (files.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Downloading ${files.length} files...')),
    );

    final result = await _controller.downloadSelectedFiles();

    if (!mounted) return;

    result.when(
      success: (_) {
        messenger.showSnackBar(
          SnackBar(content: Text('Downloaded ${files.length} files')),
        );
      },
      loading: () {},
      error: (message, exception) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Download failed: $message'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedFiles() async {
    final files = _controller.value.selectedFiles;
    if (files.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await _showDeleteConfirmation(
      files.map((f) => f.displayName).toList(),
    );
    if (!confirmed) return;

    final result = await _controller.deleteSelectedFiles();

    if (!mounted) return;

    result.when(
      success: (_) {
        messenger.showSnackBar(
          SnackBar(content: Text('Deleted ${files.length} items')),
        );
      },
      loading: () {},
      error: (message, exception) {
        messenger.showSnackBar(
          SnackBar(content: Text('Delete failed: $message')),
        );
      },
    );
  }

  Future<void> _onRenameFile(FileInfo file) async {
    await showDialog<void>(
      context: context,
      builder: (context) => FileRenameDialog(
        file: file,
        onRename: (newName) async {
          final result = await _controller.renameFile(file, newName);
          result.when(
            success: (_) {
              // Success message is handled by the dialog
            },
            loading: () {},
            error: (message, exception) {
              throw Exception(message);
            },
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(List<String> fileNames) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever),
        title: const Text('Confirm Delete'),
        content: Text(
          fileNames.length == 1
              ? 'Are you sure you want to delete "${fileNames.first}"?'
              : 'Delete ${fileNames.length} items?\n\n${fileNames.take(3).join(', ')}${fileNames.length > 3 ? '...' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
