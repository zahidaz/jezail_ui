import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';

final class FileOperationsPanel extends StatelessWidget {
  const FileOperationsPanel({
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
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Advanced Operations'),
      leading: const Icon(Icons.security),
      children: [
        _buildQuickPermissionButtons(context),
        const Divider(),
        _buildPermissionEditor(context),
        const Divider(),
        _buildOwnershipEditor(context),
        const Divider(),
        _buildPentestingTools(context),
      ],
    );
  }

  Widget _buildQuickPermissionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Permissions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickPermButton(context, '755', 'rwxr-xr-x', 'Executable'),
              _buildQuickPermButton(context, '644', 'rw-r--r--', 'Read/Write'),
              _buildQuickPermButton(context, '600', 'rw-------', 'Owner Only'),
              _buildQuickPermButton(context, '777', 'rwxrwxrwx', 'Full Access'),
              _buildQuickPermButton(context, '000', '---------', 'No Access'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPermButton(BuildContext context, String octal, String symbolic, String description) {
    return Tooltip(
      message: '$description ($symbolic)',
      child: OutlinedButton(
        onPressed: () => _changePermissions(context, octal),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(octal),
      ),
    );
  }

  Widget _buildPermissionEditor(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock),
      title: const Text('Edit Permissions'),
      subtitle: Text('Current: ${file.permissions}'),
      onTap: () => _showPermissionDialog(context),
    );
  }

  Widget _buildOwnershipEditor(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('Change Ownership'),
      subtitle: Text('${file.owner}:${file.group}'),
      onTap: () => _showOwnershipDialog(context),
    );
  }

  Widget _buildPentestingTools(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pentesting Actions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPentestButton(
                context,
                'Make Executable',
                Icons.play_arrow,
                () => _makeExecutable(context),
                enabled: !file.isDirectory && !file.permissions.contains('x'),
              ),
              _buildPentestButton(
                context,
                'Remove Execute',
                Icons.block,
                () => _removeExecutable(context),
                enabled: file.permissions.contains('x'),
              ),
              _buildPentestButton(
                context,
                'World Writable',
                Icons.public,
                () => _makeWorldWritable(context),
                enabled: !file.permissions.endsWith('w'),
              ),
              _buildPentestButton(
                context,
                'Hide from Others',
                Icons.visibility_off,
                () => _hideFromOthers(context),
                enabled: file.permissions.length > 7 && file.permissions[7] != '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPentestButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return FilledButton.tonalIcon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _changePermissions(BuildContext context, String permissions) async {
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      await repository.changePermissions(_getFilePath(), permissions);
      messenger.showSnackBar(
        SnackBar(content: Text('Changed permissions to $permissions')),
      );
      onChanged();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to change permissions: $e')),
      );
    }
  }

  Future<void> _makeExecutable(BuildContext context) async {
    final currentOctal = file.parsedPermissions.toOctal();
    final owner = int.parse(currentOctal[0]);
    final group = int.parse(currentOctal[1]);
    final others = int.parse(currentOctal[2]);
    
    final newPermissions = '${owner | 1}${group | 1}${others | 1}';
    await _changePermissions(context, newPermissions);
  }

  Future<void> _removeExecutable(BuildContext context) async {
    final currentOctal = file.parsedPermissions.toOctal();
    final owner = int.parse(currentOctal[0]);
    final group = int.parse(currentOctal[1]);
    final others = int.parse(currentOctal[2]);
    
    final newPermissions = '${owner & 6}${group & 6}${others & 6}';
    await _changePermissions(context, newPermissions);
  }

  Future<void> _makeWorldWritable(BuildContext context) async {
    final currentOctal = file.parsedPermissions.toOctal();
    final owner = int.parse(currentOctal[0]);
    final group = int.parse(currentOctal[1]);
    final others = int.parse(currentOctal[2]);
    
    final newPermissions = '$owner$group${others | 2}';
    await _changePermissions(context, newPermissions);
  }

  Future<void> _hideFromOthers(BuildContext context) async {
    final currentOctal = file.parsedPermissions.toOctal();
    final owner = int.parse(currentOctal[0]);
    final group = int.parse(currentOctal[1]);
    
    final newPermissions = '$owner${group}0';
    await _changePermissions(context, newPermissions);
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => PermissionEditorDialog(
        file: file,
        repository: repository,
        filePath: _getFilePath(),
        onChanged: onChanged,
      ),
    );
  }

  void _showOwnershipDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => OwnershipEditorDialog(
        file: file,
        repository: repository,
        filePath: _getFilePath(),
        onChanged: onChanged,
      ),
    );
  }

  String _getFilePath() {
    return currentPath == '/' 
        ? '/${file.displayName}' 
        : '$currentPath/${file.displayName}';
  }
}

final class PermissionEditorDialog extends StatefulWidget {
  const PermissionEditorDialog({
    super.key,
    required this.file,
    required this.repository,
    required this.filePath,
    required this.onChanged,
  });

  final FileInfo file;
  final FileRepository repository;
  final String filePath;
  final VoidCallback onChanged;

  @override
  State<PermissionEditorDialog> createState() => _PermissionEditorDialogState();
}

final class _PermissionEditorDialogState extends State<PermissionEditorDialog> {
  late final FilePermissions _permissions;
  late bool _ownerRead, _ownerWrite, _ownerExecute;
  late bool _groupRead, _groupWrite, _groupExecute;
  late bool _othersRead, _othersWrite, _othersExecute;

  @override
  void initState() {
    super.initState();
    _permissions = widget.file.parsedPermissions;
    _ownerRead = _permissions.ownerRead;
    _ownerWrite = _permissions.ownerWrite;
    _ownerExecute = _permissions.ownerExecute;
    _groupRead = _permissions.groupRead;
    _groupWrite = _permissions.groupWrite;
    _groupExecute = _permissions.groupExecute;
    _othersRead = _permissions.othersRead;
    _othersWrite = _permissions.othersWrite;
    _othersExecute = _permissions.othersExecute;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Permissions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'File: ${widget.file.displayName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildPermissionGroup('Owner', _ownerRead, _ownerWrite, _ownerExecute,
              (r, w, x) {
                setState(() {
                  _ownerRead = r;
                  _ownerWrite = w;
                  _ownerExecute = x;
                });
              }),
            _buildPermissionGroup('Group', _groupRead, _groupWrite, _groupExecute,
              (r, w, x) {
                setState(() {
                  _groupRead = r;
                  _groupWrite = w;
                  _groupExecute = x;
                });
              }),
            _buildPermissionGroup('Others', _othersRead, _othersWrite, _othersExecute,
              (r, w, x) {
                setState(() {
                  _othersRead = r;
                  _othersWrite = w;
                  _othersExecute = x;
                });
              }),
            const SizedBox(height: 16),
            Text(
              'Octal: ${_calculateOctal()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Symbolic: ${_calculateSymbolic()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _applyChanges,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPermissionGroup(
    String title,
    bool read, bool write, bool execute,
    void Function(bool r, bool w, bool x) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Read'),
                value: read,
                onChanged: (value) => onChanged(value ?? false, write, execute),
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Write'),
                value: write,
                onChanged: (value) => onChanged(read, value ?? false, execute),
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Execute'),
                value: execute,
                onChanged: (value) => onChanged(read, write, value ?? false),
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _calculateOctal() {
    int owner = (_ownerRead ? 4 : 0) + (_ownerWrite ? 2 : 0) + (_ownerExecute ? 1 : 0);
    int group = (_groupRead ? 4 : 0) + (_groupWrite ? 2 : 0) + (_groupExecute ? 1 : 0);
    int others = (_othersRead ? 4 : 0) + (_othersWrite ? 2 : 0) + (_othersExecute ? 1 : 0);
    return '$owner$group$others';
  }

  String _calculateSymbolic() {
    return '${_ownerRead ? 'r' : '-'}${_ownerWrite ? 'w' : '-'}${_ownerExecute ? 'x' : '-'}'
           '${_groupRead ? 'r' : '-'}${_groupWrite ? 'w' : '-'}${_groupExecute ? 'x' : '-'}'
           '${_othersRead ? 'r' : '-'}${_othersWrite ? 'w' : '-'}${_othersExecute ? 'x' : '-'}';
  }

  Future<void> _applyChanges() async {
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      await widget.repository.changePermissions(widget.filePath, _calculateOctal());
      messenger.showSnackBar(
        const SnackBar(content: Text('Permissions updated successfully')),
      );
      widget.onChanged();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update permissions: $e')),
      );
    }
  }
}

final class OwnershipEditorDialog extends StatefulWidget {
  const OwnershipEditorDialog({
    super.key,
    required this.file,
    required this.repository,
    required this.filePath,
    required this.onChanged,
  });

  final FileInfo file;
  final FileRepository repository;
  final String filePath;
  final VoidCallback onChanged;

  @override
  State<OwnershipEditorDialog> createState() => _OwnershipEditorDialogState();
}

final class _OwnershipEditorDialogState extends State<OwnershipEditorDialog> {
  late final TextEditingController _ownerController;
  late final TextEditingController _groupController;

  @override
  void initState() {
    super.initState();
    _ownerController = TextEditingController(text: widget.file.owner);
    _groupController = TextEditingController(text: widget.file.group);
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Ownership'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'File: ${widget.file.displayName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ownerController,
            decoration: const InputDecoration(
              labelText: 'Owner',
              hintText: 'root, shell, system, etc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _groupController,
            decoration: const InputDecoration(
              labelText: 'Group',
              hintText: 'root, shell, system, etc.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _buildCommonOwners(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _applyChanges,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildCommonOwners() {
    final commonOwners = ['root', 'shell', 'system', 'nobody'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Common:', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: commonOwners.map((owner) => 
            ActionChip(
              label: Text(owner),
              onPressed: () {
                _ownerController.text = owner;
                _groupController.text = owner;
              },
            ),
          ).toList(),
        ),
      ],
    );
  }

  Future<void> _applyChanges() async {
    final messenger = ScaffoldMessenger.of(context);
    final newOwner = _ownerController.text.trim();
    final newGroup = _groupController.text.trim();
    
    if (newOwner.isEmpty || newGroup.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Owner and group cannot be empty')),
      );
      return;
    }

    try {
      await widget.repository.changeOwner(widget.filePath, newOwner);
      await widget.repository.changeGroup(widget.filePath, newGroup);
      messenger.showSnackBar(
        SnackBar(content: Text('Changed ownership to $newOwner:$newGroup')),
      );
      widget.onChanged();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to change ownership: $e')),
      );
    }
  }
}