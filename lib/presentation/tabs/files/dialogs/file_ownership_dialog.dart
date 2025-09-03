import 'package:flutter/material.dart';
import 'package:jezail_ui/models/files/file_info.dart';

final class FileOwnershipDialog extends StatefulWidget {
  const FileOwnershipDialog({
    super.key,
    required this.file,
    required this.onSave,
  });

  final FileInfo file;
  final Future<void> Function(String owner, String group) onSave;

  @override
  State<FileOwnershipDialog> createState() => _FileOwnershipDialogState();
}

final class _FileOwnershipDialogState extends State<FileOwnershipDialog> {
  late TextEditingController ownerController;
  late TextEditingController groupController;

  @override
  void initState() {
    super.initState();
    ownerController = TextEditingController(text: widget.file.owner);
    groupController = TextEditingController(text: widget.file.group);
  }

  @override
  void dispose() {
    ownerController.dispose();
    groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Edit Ownership - ${widget.file.displayName}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ownerController,
            decoration: const InputDecoration(
              labelText: 'Owner',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: groupController,
            decoration: const InputDecoration(
              labelText: 'Group',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.group),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await widget.onSave(ownerController.text.trim(), groupController.text.trim());
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}