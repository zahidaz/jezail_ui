import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/presentation/tabs/files/dialogs/properties/file_operations_panel.dart';

class FilePropertiesDialog extends StatefulWidget {
  const FilePropertiesDialog({
    super.key,
    required this.file,
    required this.repository,
    required this.currentPath,
    required this.onChanged,
  });

  final FileInfo file;
  final FileRepository repository;
  final String currentPath;
  final VoidCallback onChanged;

  @override
  State<FilePropertiesDialog> createState() => _FilePropertiesDialogState();
}

class _FilePropertiesDialogState extends State<FilePropertiesDialog> {
  late FileInfo _currentFile;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    _refreshFileInfo();
  }

  Future<void> _refreshFileInfo() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final filePath = widget.currentPath == '/' 
          ? '/${widget.file.displayName}' 
          : '${widget.currentPath}/${widget.file.displayName}';
      
      final updatedFile = await widget.repository.getFileInfo(filePath);
      
      if (mounted) {
        setState(() {
          _currentFile = updatedFile;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh file info: $e')),
        );
      }
    }
  }

  void _onFileChanged() {
    _refreshFileInfo();
    widget.onChanged();
  }

  Future<void> _copyToClipboard(String text, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy $label: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 700,
        child: Column(
          children: [
            AppBar(
              title: Row(
                children: [
                  Icon(
                    _currentFile.isDirectory ? Icons.folder : Icons.insert_drive_file,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Properties: ${_currentFile.displayName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              automaticallyImplyLeading: false,
              actions: [
                if (_isRefreshing)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshFileInfo,
                    tooltip: 'Refresh file info',
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FileOperationsPanel(
                      file: _currentFile,
                      repository: widget.repository,
                      currentPath: widget.currentPath,
                      onChanged: _onFileChanged,
                    ),
                    const SizedBox(height: 16),
                    _buildFileInfoCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFileInfoCard() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Information',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', _currentFile.displayName),
            _buildInfoRow('Path', '${widget.currentPath}/${_currentFile.displayName}'),
            _buildInfoRow('Type', _currentFile.isDirectory ? 'Directory' : 'File'),
            if (!_currentFile.isDirectory) _buildInfoRow('Size', _currentFile.sizeFormatted),
            if (_currentFile.mimeType != null) _buildInfoRow('MIME Type', _currentFile.mimeType!),
            _buildInfoRow('Permissions', _currentFile.permissions, isMonospace: true),
            _buildInfoRow('Owner', _currentFile.owner),
            _buildInfoRow('Group', _currentFile.group),
            _buildInfoRow('Last Modified', _currentFile.lastModified),
            if (_currentFile.isSymlink) 
              _buildInfoRow('Type', 'Symbolic Link', color: theme.colorScheme.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false, Color? color}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: isMonospace ? 'monospace' : null,
                color: color,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 16,
              color: theme.colorScheme.outline,
            ),
            onPressed: () => _copyToClipboard(value, label),
            tooltip: 'Copy $label',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
}