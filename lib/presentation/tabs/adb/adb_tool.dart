import 'package:flutter/material.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/models/tools/adb_status.dart';
import 'package:jezail_ui/repositories/adb_repository.dart';

class _StatusItem {
  final String label;
  final String value;
  final Color? color;

  _StatusItem(this.label, this.value, [this.color]);
}

class _ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  _ActionButton(this.label, this.icon, this.onPressed);
}

class AdbTool extends StatefulWidget {
  final AdbRepository repository;

  const AdbTool({super.key, required this.repository});

  @override
  State<AdbTool> createState() => _AdbToolState();
}

class _AdbToolState extends State<AdbTool> {
  AdbStatus? adbStatus;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => isLoading = true);
    try {
      final adb = await widget.repository.getStatus();
      if (mounted) setState(() => adbStatus = adb);
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load ADB status: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _startAdb() async {
    setState(() => isLoading = true);
    try {
      await widget.repository.start();
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('ADB started successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to start ADB: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _stopAdb() async {
    setState(() => isLoading = true);
    try {
      await widget.repository.stop();
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('ADB stopped successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to stop ADB: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showAdbKeyDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install ADB Public Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your ADB public key below:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will install the key for ADB authentication.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Install'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => isLoading = true);
      try {
        await widget.repository.installKey(result);
        if (mounted) {
          context.showSuccessSnackBar('ADB key installed successfully');
        }
      } catch (e) {
        if (mounted) context.showErrorSnackBar('Failed to install ADB key: $e');
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  List<_StatusItem> _getStatusItems() {
    if (adbStatus == null) return [];
    return [
      _StatusItem(
        'Status',
        adbStatus!.isRunning ? 'Running' : 'Stopped',
        adbStatus!.isRunning ? Colors.green : Colors.orange,
      ),
      _StatusItem('Port', adbStatus!.port),
    ];
  }

  List<_ActionButton> _getActions() {
    final running = adbStatus?.isRunning == true;
    return [
      if (!running)
        _ActionButton('Start', Icons.play_arrow, isLoading ? null : _startAdb),
      if (running)
        _ActionButton('Stop', Icons.stop, isLoading ? null : _stopAdb),
      _ActionButton(
        'Install Key',
        Icons.vpn_key,
        isLoading ? null : _showAdbKeyDialog,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.developer_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'ADB',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Android Debug Bridge'),
              trailing: IconButton(
                onPressed: isLoading ? null : _loadStatus,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh ADB status',
              ),
            ),
            if (_getStatusItems().isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._getStatusItems().map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${item.label}:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.value,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    item.color ??
                                    Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_getActions().isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getActions()
                    .map(
                      (action) => ActionChip(
                        avatar: Icon(action.icon, size: 18),
                        label: Text(action.label),
                        onPressed: action.onPressed,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
