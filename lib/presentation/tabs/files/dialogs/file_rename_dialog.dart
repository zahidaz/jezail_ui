import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class FileRenameDialog extends StatefulWidget {
  const FileRenameDialog({
    super.key,
    required this.file,
    required this.onRename,
  });

  final FileInfo file;
  final Future<void> Function(String newName) onRename;

  @override
  State<FileRenameDialog> createState() => _FileRenameDialogState();
}

class _FileRenameDialogState extends State<FileRenameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isRenaming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.file.displayName);
    
    if (!widget.file.isDirectory) {
      final name = widget.file.displayName;
      final dotIndex = name.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: dotIndex,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.file.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text('Rename ${widget.file.isDirectory ? 'Directory' : 'File'}'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current name: ${widget.file.displayName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New name',
                hintText: 'Enter new name...',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  widget.file.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
                ),
                errorText: _error,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name cannot be empty';
                }
                if (value.trim() == widget.file.displayName) {
                  return 'New name must be different';
                }
                if (value.contains('/')) {
                  return 'Name cannot contain forward slashes';
                }
                if (value.startsWith('.') && value.length == 1) {
                  return 'Invalid name';
                }
                return null;
              },
              enabled: !_isRenaming,
              autofocus: true,
              onFieldSubmitted: (_) => _handleRename(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRenaming ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isRenaming ? null : _handleRename,
          child: _isRenaming
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Rename'),
        ),
      ],
    );
  }

  Future<void> _handleRename() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _controller.text.trim();
    
    setState(() {
      _isRenaming = true;
      _error = null;
    });

    try {
      await widget.onRename(newName);
      if (mounted) {
        Navigator.pop(context, true);
        context.showSuccessSnackBar('${widget.file.isDirectory ? 'Directory' : 'File'} renamed successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('FileOperationException: ', '');
          _isRenaming = false;
        });
      }
    }
  }
}