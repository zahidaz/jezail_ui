import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';


class FileEditDialog extends StatefulWidget {
  const FileEditDialog({
    super.key,
    required this.file,
    required this.repository,
    required this.currentPath,
  });

  final FileInfo file;
  final FileRepository repository;
  final String currentPath;

  @override
  State<FileEditDialog> createState() => _FileEditDialogState();
}

class _FileEditDialogState extends State<FileEditDialog> {
  late TextEditingController _controller;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadFileContent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFileContent() async {
    try {
      final filePath = widget.currentPath == '/' 
          ? '/${widget.file.displayName}' 
          : '${widget.currentPath}/${widget.file.displayName}';
      
      final content = await widget.repository.readFile(filePath);
      
      setState(() {
        _controller.text = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final filePath = widget.currentPath == '/' 
          ? '/${widget.file.displayName}' 
          : '${widget.currentPath}/${widget.file.displayName}';
      
      await widget.repository.writeFile(filePath, _controller.text);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${widget.file.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 900,
        height: 700,
        child: Column(
          children: [
            AppBar(
              title: Text('Edit: ${widget.file.displayName}'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveFile,
                  child: _isSaving 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                const SizedBox(width: 16),
              ],
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading file: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFileContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'File content...',
        ),
      ),
    );
  }
}
