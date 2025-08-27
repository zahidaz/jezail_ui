import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/tool_repository.dart';
import 'package:jezail_ui/models/tools/adb_status.dart';
import 'package:jezail_ui/models/tools/frida_status.dart';
import 'package:jezail_ui/models/tools/frida_info.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

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
      
      if (mounted) {
        setState(() {
          adbStatus = adb;
          fridaStatus = frida;
          this.fridaInfo = fridaInfo;
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load tools status: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fridaAction(String action) async {
    setState(() => isLoading = true);
    try {
      await switch (action) {
        'start' => widget.repository.startFrida(),
        'stop' => widget.repository.stopFrida(),
        'install' => widget.repository.installFrida(),
        'update' => widget.repository.updateFrida(),
        _ => throw ArgumentError('Unknown action: $action'),
      };
      
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('Frida $action completed successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Frida $action failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _adbAction(String action) async {
    setState(() => isLoading = true);
    try {
      await switch (action) {
        'start' => widget.repository.startAdb(),
        'stop' => widget.repository.stopAdb(),
        _ => throw ArgumentError('Unknown action: $action'),
      };
      
      await _loadStatus();
      if (mounted) context.showSuccessSnackBar('ADB $action completed successfully');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('ADB $action failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              _buildHeader(),
              const SizedBox(height: 16),
              if (isLoading) 
                _buildLoadingCard()
              else ...[
                _buildFridaCard(),
                const SizedBox(height: 16),
                _buildAdbCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: isLoading ? null : _loadStatus,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh status',
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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

  Widget _buildFridaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.bug_report,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Frida',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text('Dynamic Instrumentation Toolkit'),
            ),
            if (fridaStatus != null || fridaInfo != null) ...[
              const SizedBox(height: 8),
              _buildStatusSection([
                if (fridaStatus != null) ...[
                  _StatusInfo('Status', fridaStatus!.isRunning ? 'Running' : 'Stopped', 
                    fridaStatus!.isRunning ? Colors.green : Colors.orange),
                  _StatusInfo('Port', fridaStatus!.port),
                  _StatusInfo('Installed Version', fridaStatus!.version),
                ],
                if (fridaInfo != null) ...[
                  _StatusInfo('Current Version', fridaInfo!.currentVersion),
                  _StatusInfo('Latest Version', fridaInfo!.latestVersion),
                  _StatusInfo('Needs Update', fridaInfo!.needsUpdate ? 'Yes' : 'No',
                    fridaInfo!.needsUpdate ? Colors.orange : Colors.green),
                  _StatusInfo('Install Path', fridaInfo!.installPath),
                ],
              ]),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  onPressed: (isLoading || fridaStatus?.isRunning == true || fridaStatus?.version == 'not installed') 
                    ? null : () => _fridaAction('start'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                  onPressed: (isLoading || fridaStatus?.isRunning != true) 
                    ? null : () => _fridaAction('stop'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.download, size: 18),
                  label: const Text('Install'),
                  onPressed: isLoading ? null : () => _fridaAction('install'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.update, size: 18),
                  label: const Text('Update'),
                  onPressed: isLoading ? null : () => _fridaAction('update'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdbCard() {
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text('Android Debug Bridge'),
            ),
            if (adbStatus != null) ...[
              const SizedBox(height: 8),
              _buildStatusSection([
                _StatusInfo('Status', adbStatus!.isRunning ? 'Running' : 'Stopped',
                  adbStatus!.isRunning ? Colors.green : Colors.orange),
                _StatusInfo('Port', adbStatus!.port),
              ]),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                  onPressed: (isLoading || adbStatus?.isRunning == true) 
                    ? null : () => _adbAction('start'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                  onPressed: (isLoading || adbStatus?.isRunning != true) 
                    ? null : () => _adbAction('stop'),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(List<_StatusInfo> statusList) {
    return Column(
      children: statusList.map((status) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '${status.label}:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                status.value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: status.color ?? Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _StatusInfo {
  final String label;
  final String value;
  final Color? color;

  _StatusInfo(this.label, this.value, [this.color]);
}