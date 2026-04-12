import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jezail_ui/app_config.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/models/tools/frida_info.dart';
import 'package:jezail_ui/models/tools/frida_status.dart';
import 'package:jezail_ui/repositories/frida_repository.dart';
import 'package:jezail_ui/presentation/widgets/tool_status_card.dart';

class FridaTab extends StatefulWidget {
  final FridaRepository repository;

  const FridaTab({super.key, required this.repository});

  @override
  State<FridaTab> createState() => _FridaTabState();
}

class _FridaTabState extends State<FridaTab> {
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

  void _showConfigDialog() async {
    Map<String, dynamic>? config;
    try {
      config = await widget.repository.getConfig();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load config: $e');
      return;
    }
    if (!mounted) return;

    final portController = TextEditingController(text: config['port']?.toString() ?? '');
    final binaryController = TextEditingController(text: config['binaryName']?.toString() ?? '');

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Frida Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: binaryController,
                decoration: const InputDecoration(
                  labelText: 'Binary Name',
                  border: OutlineInputBorder(),
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
              onPressed: () => Navigator.of(context).pop({
                'port': int.tryParse(portController.text) ?? config!['port'],
                'binaryName': binaryController.text,
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      );

    if (result != null && mounted) {
      setState(() => isLoading = true);
      try {
        await widget.repository.updateConfig(result);
        await _loadStatus();
        if (mounted) context.showSuccessSnackBar('Frida config updated');
      } catch (e) {
        if (mounted) context.showErrorSnackBar('Failed to update config: $e');
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
    } finally {
      portController.dispose();
      binaryController.dispose();
    }
  }

  List<StatusItem> _getStatusItems() {
    final items = <StatusItem>[];
    if (fridaStatus != null) {
      items.addAll([
        StatusItem(
          'Status',
          fridaStatus!.isRunning ? 'Running' : 'Stopped',
          fridaStatus!.isRunning ? Colors.green : Colors.orange,
        ),
        StatusItem('Port', fridaStatus!.port),
        StatusItem('Installed Version', fridaStatus!.version),
      ]);
    }
    if (fridaInfo != null) {
      items.addAll([
        StatusItem('Current Version', fridaInfo!.currentVersion),
        StatusItem('Latest Version', fridaInfo!.latestVersion),
        StatusItem(
          'Needs Update',
          fridaInfo!.needsUpdate ? 'Yes' : 'No',
          fridaInfo!.needsUpdate ? Colors.orange : Colors.green,
        ),
        StatusItem('Install Path', fridaInfo!.installPath, null, true, () {
          final dirPath = fridaInfo!.installPath;
          final parentPath = dirPath.contains('/')
              ? dirPath.substring(0, dirPath.lastIndexOf('/'))
              : dirPath;
          context.go('/files?path=${Uri.encodeComponent(parentPath)}');
        }),
      ]);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final installed = fridaStatus?.version != 'not installed';
    final running = fridaStatus?.isRunning == true;
    final needsUpdate = fridaInfo?.needsUpdate == true;

    return ToolStatusCard(
      title: 'Frida',
      subtitle: 'Dynamic Instrumentation Toolkit',
      icon: Icons.api,
      isLoading: isLoading,
      onRefresh: _loadStatus,
      showLoadingIndicator: true,
      statusItems: _getStatusItems(),
      actions: [
        if (!installed)
          ActionButton('Install', Icons.download, isLoading ? null : _installFrida),
        if (installed && !running)
          ActionButton('Start', Icons.play_arrow, isLoading ? null : _startFrida),
        if (running)
          ActionButton('Stop', Icons.stop, isLoading ? null : _stopFrida),
        if (needsUpdate)
          ActionButton('Update', Icons.update, isLoading ? null : _updateFrida),
        ActionButton('Config', Icons.settings, isLoading ? null : _showConfigDialog),
        ActionButton(
          'Refrida',
          Icons.code,
          () => launchUrl(
            Uri.parse('${AppConfig.baseUrl}/refrida'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}
