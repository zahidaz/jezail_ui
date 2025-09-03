import 'package:flutter/material.dart';
import 'package:jezail_ui/models/files/file_info.dart';

final class FilePermissionsDialog extends StatefulWidget {
  const FilePermissionsDialog({
    super.key,
    required this.file,
    required this.onSave,
  });

  final FileInfo file;
  final Future<void> Function(String permissions) onSave;

  @override
  State<FilePermissionsDialog> createState() => _FilePermissionsDialogState();
}

final class _FilePermissionsDialogState extends State<FilePermissionsDialog> {
  late FilePermissions permissions;
  late TextEditingController octalController;

  @override
  void initState() {
    super.initState();
    permissions = widget.file.parsedPermissions;
    octalController = TextEditingController(text: permissions.toOctal());
  }

  @override
  void dispose() {
    octalController.dispose();
    super.dispose();
  }

  void _updateFromOctal(String octal) {
    if (octal.length == 3 && int.tryParse(octal) != null) {
      final digits = octal.split('').map(int.parse).toList();
      setState(() {
        permissions = FilePermissions(
          ownerRead: (digits[0] & 4) != 0,
          ownerWrite: (digits[0] & 2) != 0,
          ownerExecute: (digits[0] & 1) != 0,
          groupRead: (digits[1] & 4) != 0,
          groupWrite: (digits[1] & 2) != 0,
          groupExecute: (digits[1] & 1) != 0,
          othersRead: (digits[2] & 4) != 0,
          othersWrite: (digits[2] & 2) != 0,
          othersExecute: (digits[2] & 1) != 0,
        );
      });
    }
  }

  void _updateOctal() {
    octalController.text = permissions.toOctal();
  }

  void _updateOwnerPermissions(bool r, bool w, bool x) {
    setState(() {
      permissions = permissions.copyWith(ownerRead: r, ownerWrite: w, ownerExecute: x);
      _updateOctal();
    });
  }

  void _updateGroupPermissions(bool r, bool w, bool x) {
    setState(() {
      permissions = permissions.copyWith(groupRead: r, groupWrite: w, groupExecute: x);
      _updateOctal();
    });
  }

  void _updateOthersPermissions(bool r, bool w, bool x) {
    setState(() {
      permissions = permissions.copyWith(othersRead: r, othersWrite: w, othersExecute: x);
      _updateOctal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Edit Permissions - ${widget.file.displayName}'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: octalController,
            decoration: const InputDecoration(
              labelText: 'Octal (e.g., 755)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            onChanged: _updateFromOctal,
          ),
          const SizedBox(height: 16),
          Text('Permissions:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildPermissionGroup('Owner', permissions.ownerRead, permissions.ownerWrite, permissions.ownerExecute, _updateOwnerPermissions),
          _buildPermissionGroup('Group', permissions.groupRead, permissions.groupWrite, permissions.groupExecute, _updateGroupPermissions),
          _buildPermissionGroup('Others', permissions.othersRead, permissions.othersWrite, permissions.othersExecute, _updateOthersPermissions),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await widget.onSave(permissions.toOctal());
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildPermissionGroup(String label, bool read, bool write, bool execute, Function(bool, bool, bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: Row(
              children: [
                Checkbox(value: read, onChanged: (v) => onChanged(v ?? false, write, execute)),
                const Text('Read'),
                const SizedBox(width: 16),
                Checkbox(value: write, onChanged: (v) => onChanged(read, v ?? false, execute)),
                const Text('Write'),
                const SizedBox(width: 16),
                Checkbox(value: execute, onChanged: (v) => onChanged(read, write, v ?? false)),
                const Text('Execute'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}