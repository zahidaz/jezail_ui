import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class FileUploadDialog extends StatefulWidget {
  const FileUploadDialog({
    super.key,
    required this.repository,
    required this.currentPath,
    required this.onUploaded,
  });

  final FileRepository repository;
  final String currentPath;
  final Future<void> Function() onUploaded;

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog> {
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _currentUploadFile;

  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles = result.files;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final fileName = file.name;
        final fileBytes = file.bytes;

        if (fileBytes == null) continue;

        setState(() {
          _currentUploadFile = fileName;
          _uploadProgress = (i / _selectedFiles.length);
        });

        final remotePath = widget.currentPath == '/' 
            ? '/$fileName' 
            : '${widget.currentPath}/$fileName';

        await widget.repository.uploadFile(remotePath, fileBytes, filename: fileName);
      }

      setState(() {
        _uploadProgress = 1.0;
      });

      if (mounted) {
        Navigator.pop(context);
        await widget.onUploaded();
        if (mounted) {
          context.showSuccessSnackBar('Uploaded ${_selectedFiles.length} files');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        context.showErrorSnackBar('Upload failed: $e');
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_upload, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Upload Files'),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
            if (_selectedFiles.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload, size: 64),
                      const SizedBox(height: 16),
                      const Text('No files selected'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isUploading ? null : _selectFiles,
                        child: const Text('Select Files'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_selectedFiles.length} files selected'),
                  TextButton(
                    onPressed: _isUploading ? null : _selectFiles,
                    child: const Text('Add More'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = _selectedFiles[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file.name),
                        subtitle: Text(_formatFileSize(file.size)),
                        trailing: _isUploading 
                            ? null 
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removeFile(index),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_isUploading) ...[
              const SizedBox(height: 16),
              if (_currentUploadFile != null)
                Text('Uploading: $_currentUploadFile'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedFiles.isEmpty || _isUploading ? null : _upload,
          child: _isUploading ? const Text('Uploading...') : const Text('Upload'),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
