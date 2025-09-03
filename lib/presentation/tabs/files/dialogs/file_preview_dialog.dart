import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';


class FilePreviewDialog extends StatelessWidget {
  const FilePreviewDialog({
    super.key,
    required this.file,
    required this.repository,
    required this.currentPath,
    required this.onEdit,
    required this.onDownload,
    required this.onChanged,
  });

  final FileInfo file;
  final FileRepository repository;
  final String currentPath;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            AppBar(
              title: Text(file.displayName),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _handleEditRequest(context),
                  tooltip: 'Edit file',
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: onDownload,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildFileContent(context),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadFileContent(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load file',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final content = snapshot.data ?? '';
        
        if (!file.isLikelyTextFile && content.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This file (${file.mimeType ?? 'unknown type'}) may contain binary data. Content might appear garbled.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          );
        }
        
        return SizedBox(
          width: double.infinity,
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        );
      },
    );
  }

  void _handleEditRequest(BuildContext context) {
    if (file.isLikelyTextFile) {
      Navigator.pop(context);
      onEdit();
    } else {
      _showEditConfirmationDialog(context);
    }
  }

  void _showEditConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.secondary,
          size: 32,
        ),
        title: const Text('Edit Non-Text File?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This file appears to be a binary file (${file.mimeType ?? 'unknown type'}).',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Editing binary files as text may:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Corrupt the file', style: theme.textTheme.bodySmall),
                  Text('• Display unreadable content', style: theme.textTheme.bodySmall),
                  Text('• Cause application crashes', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Do you want to proceed anyway?',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close preview dialog
              onEdit(); // Proceed to edit
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
            child: const Text('Edit Anyway'),
          ),
        ],
      ),
    );
  }

  Future<String> _loadFileContent() async {
    final filePath = currentPath == '/' 
        ? '/${file.displayName}' 
        : '$currentPath/${file.displayName}';
    return await repository.readFile(filePath);
  }
}
