import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/models/tools/adb_status.dart';
import 'package:jezail_ui/models/tools/frida_info.dart';
import 'package:jezail_ui/models/tools/frida_status.dart';
import 'package:jezail_ui/repositories/tool_repository.dart';

enum _ToolAction { fridaStart, fridaStop, fridaInstall, fridaUpdate, adbStart, adbStop, adbInstallKey }

class ToolsTab extends StatefulWidget {
  final ToolRepository repository;

  const ToolsTab({super.key, required this.repository});

  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> {
  AdbStatus? adbStatus;
  FridaStatus? fridaStatus;
  FridaInfo? fridaInfo;
  bool isLoading = false;
  bool isFridaLoading = false;
  bool isAdbLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => isLoading = true);
    try {
      final (adb, frida, fridaInfo) = await (
        widget.repository.getAdbStatus(),
        widget.repository.getFridaStatus(),
        widget.repository.getFridaInfo(),
      ).wait;

      if (!mounted) return;
      setState(() {
        adbStatus = adb;
        fridaStatus = frida;
        this.fridaInfo = fridaInfo;
      });
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load tools status: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadFridaStatus() async {
    setState(() => isFridaLoading = true);
    try {
      final (frida, fridaInfo) = await (
        widget.repository.getFridaStatus(),
        widget.repository.getFridaInfo(),
      ).wait;

      if (!mounted) return;
      setState(() {
        fridaStatus = frida;
        this.fridaInfo = fridaInfo;
      });
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load Frida status: $e');
    } finally {
      if (mounted) setState(() => isFridaLoading = false);
    }
  }

  Future<void> _loadAdbStatus() async {
    setState(() => isAdbLoading = true);
    try {
      final adb = await widget.repository.getAdbStatus();

      if (!mounted) return;
      setState(() {
        adbStatus = adb;
      });
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load ADB status: $e');
    } finally {
      if (mounted) setState(() => isAdbLoading = false);
    }
  }

  Future<void> _executeAction(_ToolAction action) async {
    final isFridaAction = [
      _ToolAction.fridaStart,
      _ToolAction.fridaStop,
      _ToolAction.fridaInstall,
      _ToolAction.fridaUpdate,
    ].contains(action);
    
    final isAdbAction = [
      _ToolAction.adbStart,
      _ToolAction.adbStop,
      _ToolAction.adbInstallKey,
    ].contains(action);

    if (isFridaAction) {
      setState(() => isFridaLoading = true);
    } else if (isAdbAction) {
      setState(() => isAdbLoading = true);
    }

    try {
      switch (action) {
        case _ToolAction.fridaStart:
          await widget.repository.startFrida();
          break;
        case _ToolAction.fridaStop:
          await widget.repository.stopFrida();
          break;
        case _ToolAction.fridaInstall:
          await widget.repository.installFrida();
          break;
        case _ToolAction.fridaUpdate:
          await widget.repository.updateFrida();
          break;
        case _ToolAction.adbStart:
          await widget.repository.startAdb();
          break;
        case _ToolAction.adbStop:
          await widget.repository.stopAdb();
          break;
        case _ToolAction.adbInstallKey:
          await _showAdbKeyDialog();
          return;
      }
      
      if (isFridaAction) {
        await _loadFridaStatus();
      } else if (isAdbAction) {
        await _loadAdbStatus();
      }
      
      if (mounted) {
        context.showSuccessSnackBar('${_getActionLabel(action)} completed successfully');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('${_getActionLabel(action)} failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          if (isFridaAction) {
            isFridaLoading = false;
          } else if (isAdbAction) {
            isAdbLoading = false;
          }
        });
      }
    }
  }

  String _getActionLabel(_ToolAction action) {
    switch (action) {
      case _ToolAction.fridaStart:
        return 'Frida start';
      case _ToolAction.fridaStop:
        return 'Frida stop';
      case _ToolAction.fridaInstall:
        return 'Frida install';
      case _ToolAction.fridaUpdate:
        return 'Frida update';
      case _ToolAction.adbStart:
        return 'ADB start';
      case _ToolAction.adbStop:
        return 'ADB stop';
      case _ToolAction.adbInstallKey:
        return 'ADB key install';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              if (isLoading)
                const _LoadingCard()
              else ...[
                _ToolCard(
                  title: 'Frida',
                  subtitle: 'Dynamic Instrumentation Toolkit',
                  icon: Icons.bug_report,
                  statusItems: _buildFridaStatusItems(),
                  actions: _buildFridaActions(),
                  onRefresh: _loadFridaStatus,
                  isRefreshing: isFridaLoading,
                ),
                const SizedBox(height: 16),
                _ToolCard(
                  title: 'ADB',
                  subtitle: 'Android Debug Bridge',
                  icon: Icons.developer_mode,
                  statusItems: _buildAdbStatusItems(),
                  actions: _buildAdbActions(),
                  onRefresh: _loadAdbStatus,
                  isRefreshing: isAdbLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_StatusItem> _buildFridaStatusItems() {
    final items = <_StatusItem>[];
    
    if (fridaStatus != null) {
      items.addAll([
        _StatusItem(
          label: 'Status',
          value: fridaStatus!.isRunning ? 'Running' : 'Stopped',
          color: fridaStatus!.isRunning ? Colors.green : Colors.orange,
        ),
        _StatusItem(label: 'Port', value: fridaStatus!.port),
        _StatusItem(label: 'Installed Version', value: fridaStatus!.version),
      ]);
    }
    
    if (fridaInfo != null) {
      items.addAll([
        _StatusItem(label: 'Current Version', value: fridaInfo!.currentVersion),
        _StatusItem(label: 'Latest Version', value: fridaInfo!.latestVersion),
        _StatusItem(
          label: 'Needs Update',
          value: fridaInfo!.needsUpdate ? 'Yes' : 'No',
          color: fridaInfo!.needsUpdate ? Colors.orange : Colors.green,
        ),
        _StatusItem(
          label: 'Install Path', 
          value: fridaInfo!.installPath, 
          isClickablePath: true,
        ),
      ]);
    }
    
    return items;
  }

  List<_StatusItem> _buildAdbStatusItems() {
    if (adbStatus == null) return [];
    
    return [
      _StatusItem(
        label: 'Status',
        value: adbStatus!.isRunning ? 'Running' : 'Stopped',
        color: adbStatus!.isRunning ? Colors.green : Colors.orange,
      ),
      _StatusItem(label: 'Port', value: adbStatus!.port),
    ];
  }

  List<_ActionButton> _buildFridaActions() {
    final actions = <_ActionButton>[];
    
    final isInstalled = fridaStatus?.version != 'not installed';
    final isRunning = fridaStatus?.isRunning == true;
    final needsUpdate = fridaInfo?.needsUpdate == true;
    final isDisabled = isLoading || isFridaLoading;
    
    if (!isInstalled) {
      actions.add(_ActionButton(
        label: 'Install',
        icon: Icons.download,
        onPressed: isDisabled ? null : () => _executeAction(_ToolAction.fridaInstall),
      ));
    } else {
      if (!isRunning) {
        actions.add(_ActionButton(
          label: 'Start',
          icon: Icons.play_arrow,
          onPressed: isDisabled ? null : () => _executeAction(_ToolAction.fridaStart),
        ));
      }
      
      if (isRunning) {
        actions.add(_ActionButton(
          label: 'Stop',
          icon: Icons.stop,
          onPressed: isDisabled ? null : () => _executeAction(_ToolAction.fridaStop),
        ));
      }
      
      if (needsUpdate) {
        actions.add(_ActionButton(
          label: 'Update',
          icon: Icons.update,
          onPressed: isDisabled ? null : () => _executeAction(_ToolAction.fridaUpdate),
        ));
      }
    }
    
    return actions;
  }

  List<_ActionButton> _buildAdbActions() {
    final actions = <_ActionButton>[];
    final isRunning = adbStatus?.isRunning == true;
    final isDisabled = isLoading || isAdbLoading;
    
    if (!isRunning) {
      actions.add(_ActionButton(
        label: 'Start',
        icon: Icons.play_arrow,
        onPressed: isDisabled ? null : () => _executeAction(_ToolAction.adbStart),
      ));
    }
    
    if (isRunning) {
      actions.add(_ActionButton(
        label: 'Stop',
        icon: Icons.stop,
        onPressed: isDisabled ? null : () => _executeAction(_ToolAction.adbStop),
      ));
    }
    
    actions.add(_ActionButton(
      label: 'Install Key',
      icon: Icons.vpn_key,
      onPressed: isDisabled ? null : () => _executeAction(_ToolAction.adbInstallKey),
    ));
    
    return actions;
  }

  Future<void> _showAdbKeyDialog() async {
    final TextEditingController controller = TextEditingController();
    
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
      setState(() => isAdbLoading = true);
      try {
        await widget.repository.installAdbKey(result);
        if (mounted) {
          context.showSuccessSnackBar('ADB key installed successfully');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to install ADB key: $e');
        }
      } finally {
        if (mounted) setState(() => isAdbLoading = false);
      }
    }
  }

}


class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: 16),
              Text(
                'Loading tools status...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_StatusItem> statusItems;
  final List<_ActionButton> actions;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.statusItems,
    required this.actions,
    required this.onRefresh,
    required this.isRefreshing,
  });

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
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
              title: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(subtitle),
              trailing: IconButton(
                onPressed: isRefreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh $title status',
              ),
            ),
            if (statusItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StatusSection(items: statusItems),
              const SizedBox(height: 16),
            ],
            if (actions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map((action) => ActionChip(
                          avatar: Icon(action.icon, size: 18),
                          label: Text(action.label),
                          onPressed: action.onPressed,
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontSize: 12,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final List<_StatusItem> items;

  const _StatusSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${item.label}:',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: item.isClickablePath
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    context.go('/files?path=${item.value}');
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.folder_open,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            item.value,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              item.value,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: item.color ??
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _StatusItem {
  final String label;
  final String value;
  final Color? color;
  final bool isClickablePath;

  _StatusItem({
    required this.label, 
    required this.value, 
    this.color,
    this.isClickablePath = false,
  });
}

class _ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  _ActionButton({required this.label, required this.icon, this.onPressed});
}
