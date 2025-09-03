import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class FileCreateDialog extends StatefulWidget {
  const FileCreateDialog({
    super.key,
    required this.isDirectory,
    required this.repository,
    required this.currentPath,
    required this.onCreated,
  });

  final bool isDirectory;
  final FileRepository repository;
  final String currentPath;
  final Future<void> Function() onCreated;

  @override
  State<FileCreateDialog> createState() => _FileCreateDialogState();
}

class _FileCreateDialogState extends State<FileCreateDialog> {
  late TextEditingController _nameController;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final newPath = widget.currentPath == '/' ? '/$name' : '${widget.currentPath}/$name';
      
      if (widget.isDirectory) {
        await widget.repository.createDirectory(newPath);
      } else {
        await widget.repository.writeFile(newPath, '');
      }
      
      if (mounted) {
        Navigator.pop(context);
        await widget.onCreated();
        if (mounted) {
          context.showSuccessSnackBar('Created ${widget.isDirectory ? 'directory' : 'file'}: $name');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        context.showErrorSnackBar('Failed to create ${widget.isDirectory ? 'directory' : 'file'}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text('Create ${widget.isDirectory ? 'Directory' : 'File'}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '${widget.isDirectory ? 'Directory' : 'File'} name',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(widget.isDirectory ? Icons.folder : Icons.insert_drive_file),
            ),
            autofocus: true,
            enabled: !_isCreating,
            onSubmitted: _isCreating ? null : (_) => _create(),
          ),
          if (widget.isDirectory) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Directory will be created in the current location',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _create,
          child: _isCreating 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
