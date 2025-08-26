import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/tool_repository.dart';
import 'package:jezail_ui/core/extensions/build_context_extensions.dart';

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
      if (mounted) context.showSnackBar('Failed to load tools status: $e');
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
      if (mounted) context.showSnackBar('Frida $action completed successfully');
    } catch (e) {
      if (mounted) context.showSnackBar('Frida $action failed: $e');
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
      if (mounted) context.showSnackBar('ADB $action completed successfully');
    } catch (e) {
      if (mounted) context.showSnackBar('ADB $action failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildLoadingState() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
            Theme.of(context).colorScheme.secondaryContainer.withAlpha(100),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator.adaptive(
            strokeWidth: 3,
            backgroundColor: Theme.of(context).colorScheme.outline.withAlpha(76),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading tools status...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: isLoading ? null : _loadStatus,
            icon: Icon(
              Icons.refresh,
              size: 22,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            tooltip: 'Refresh status',
          ),
        ),
      ],
    );
  }

  Widget _buildFridaCard() {
    return _buildToolCard(
      title: 'Frida',
      subtitle: 'Dynamic Instrumentation Toolkit',
      icon: Icons.bug_report,
      containerColor: Theme.of(context).colorScheme.primaryContainer,
      iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
      statusInfo: fridaStatus != null ? [
        _StatusInfo('Status', fridaStatus!.isRunning ? 'Running' : 'Stopped', 
          fridaStatus!.isRunning ? Colors.green : Colors.orange),
        _StatusInfo('Port', fridaStatus!.port),
        _StatusInfo('Installed Version', fridaStatus!.version),
      ] : [],
      additionalInfo: fridaInfo != null ? [
        _StatusInfo('Current Version', fridaInfo!.currentVersion),
        _StatusInfo('Latest Version', fridaInfo!.latestVersion),
        _StatusInfo('Needs Update', fridaInfo!.needsUpdate ? 'Yes' : 'No',
          fridaInfo!.needsUpdate ? Colors.orange : Colors.green),
        _StatusInfo('Install Path', fridaInfo!.installPath),
      ] : [],
      actions: [
        _ActionInfo('Start', Icons.play_arrow, () => _fridaAction('start'),
          fridaStatus?.isRunning == true || fridaStatus?.version == 'not installed'),
        _ActionInfo('Stop', Icons.stop, () => _fridaAction('stop'),
          fridaStatus?.isRunning != true),
        _ActionInfo('Install', Icons.download, () => _fridaAction('install'), false),
        _ActionInfo('Update', Icons.update, () => _fridaAction('update'), false),
      ],
    );
  }

  Widget _buildAdbCard() {
    return _buildToolCard(
      title: 'ADB',
      subtitle: 'Android Debug Bridge',
      icon: Icons.developer_mode,
      containerColor: Theme.of(context).colorScheme.secondaryContainer,
      iconColor: Theme.of(context).colorScheme.onSecondaryContainer,
      statusInfo: adbStatus != null ? [
        _StatusInfo('Status', adbStatus!.isRunning ? 'Running' : 'Stopped',
          adbStatus!.isRunning ? Colors.green : Colors.orange),
        _StatusInfo('Port', adbStatus!.port),
      ] : [],
      actions: [
        _ActionInfo('Start', Icons.play_arrow, () => _adbAction('start'),
          adbStatus?.isRunning == true),
        _ActionInfo('Stop', Icons.stop, () => _adbAction('stop'),
          adbStatus?.isRunning != true),
      ],
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color containerColor,
    required Color iconColor,
    required List<_StatusInfo> statusInfo,
    List<_StatusInfo> additionalInfo = const [],
    required List<_ActionInfo> actions,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            containerColor.withAlpha(150),
            containerColor.withAlpha(100),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: containerColor.withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (statusInfo.isNotEmpty || additionalInfo.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ...statusInfo.map((info) => _buildStatusRow(info.label, info.value, info.color)),
                  ...additionalInfo.map((info) => _buildStatusRow(info.label, info.value, info.color)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) => _buildActionChip(
              action.label,
              action.icon,
              action.onPressed,
              action.isDisabled,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, [Color? statusColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: statusColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onPressed, bool isDisabled) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: (isLoading || isDisabled) ? null : onPressed,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      disabledColor: Theme.of(context).colorScheme.outline.withAlpha(100),
      labelStyle: TextStyle(
        color: (isLoading || isDisabled) 
          ? Theme.of(context).colorScheme.onSurface.withAlpha(120)
          : Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (isLoading) 
                _buildLoadingState()
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
}

class _StatusInfo {
  final String label;
  final String value;
  final Color? color;

  _StatusInfo(this.label, this.value, [this.color]);
}

class _ActionInfo {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDisabled;

  _ActionInfo(this.label, this.icon, this.onPressed, this.isDisabled);
}
