import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/models/tools/frida_info.dart';
import 'package:jezail_ui/models/tools/frida_status.dart';
import 'package:jezail_ui/repositories/frida_repository.dart';

class _StatusItem {
  final String label;
  final String value;
  final Color? color;
  final bool isPath;

  _StatusItem(this.label, this.value, [this.color, this.isPath = false]);
}

class _ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  _ActionButton(this.label, this.icon, this.onPressed);
}

class FridaTool extends StatefulWidget {
  final FridaRepository repository;

  const FridaTool({super.key, required this.repository});

  @override
  State<FridaTool> createState() => _FridaToolState();
}

class _FridaToolState extends State<FridaTool> {
  FridaStatus? fridaStatus;
  FridaInfo? fridaInfo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => isLoading = true);
    try {
      final (frida, info) = await (
        widget.repository.getStatus(),
        widget.repository.getInfo(),
      ).wait;
      if (mounted) {
        setState(() {
          fridaStatus = frida;
          fridaInfo = info;
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load Frida status: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _startFrida() async {
    setState(() => isLoading = true);
    try {
      await widget.repository.start();
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('Frida started successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to start Frida: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _stopFrida() async {
    setState(() => isLoading = true);
    try {
      await widget.repository.stop();
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('Frida stopped successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to stop Frida: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _installFrida() async {
    setState(() => isLoading = true);
    try {
      await widget.repository.install();
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('Frida installed successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to install Frida: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateFrida() async {
    setState(() => isLoading = true);
    try {
      await widget.repository.update();
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('Frida updated successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to update Frida: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<_StatusItem> _getStatusItems() {
    final items = <_StatusItem>[];
    if (fridaStatus != null) {
      items.addAll([
        _StatusItem(
          'Status',
          fridaStatus!.isRunning ? 'Running' : 'Stopped',
          fridaStatus!.isRunning ? Colors.green : Colors.orange,
        ),
        _StatusItem('Port', fridaStatus!.port),
        _StatusItem('Installed Version', fridaStatus!.version),
      ]);
    }
    if (fridaInfo != null) {
      items.addAll([
        _StatusItem('Current Version', fridaInfo!.currentVersion),
        _StatusItem('Latest Version', fridaInfo!.latestVersion),
        _StatusItem(
          'Needs Update',
          fridaInfo!.needsUpdate ? 'Yes' : 'No',
          fridaInfo!.needsUpdate ? Colors.orange : Colors.green,
        ),
        _StatusItem('Install Path', fridaInfo!.installPath, null, true),
      ]);
    }
    return items;
  }

  List<_ActionButton> _getActions() {
    final installed = fridaStatus?.version != 'not installed';
    final running = fridaStatus?.isRunning == true;
    final needsUpdate = fridaInfo?.needsUpdate == true;
    return [
      if (!installed)
        _ActionButton(
          'Install',
          Icons.download,
          isLoading ? null : _installFrida,
        ),
      if (installed && !running)
        _ActionButton(
          'Start',
          Icons.play_arrow,
          isLoading ? null : _startFrida,
        ),
      if (running)
        _ActionButton('Stop', Icons.stop, isLoading ? null : _stopFrida),
      if (needsUpdate)
        _ActionButton('Update', Icons.update, isLoading ? null : _updateFrida),
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
                Icons.api,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Frida',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Dynamic Instrumentation Toolkit'),
              trailing: IconButton(
                onPressed: isLoading ? null : _loadStatus,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Frida status',
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
                        child: item.isPath
                            ? GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: item.value),
                                  );
                                  context.showSuccessSnackBar('Path copied to clipboard');
                                },
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                item.value,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color:
                                          item.color ??
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
