import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jezail_ui/app_config.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/models/tools/adb_status.dart';
import 'package:jezail_ui/repositories/adb_repository.dart';
import 'package:jezail_ui/presentation/widgets/tool_status_card.dart';

class AdbTab extends StatefulWidget {
  final AdbRepository repository;

  const AdbTab({super.key, required this.repository});

  @override
  State<AdbTab> createState() => _AdbTabState();
}

class _AdbTabState extends State<AdbTab> {
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
    try {
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
          if (mounted) context.showSuccessSnackBar('ADB key installed successfully');
        } catch (e) {
          if (mounted) context.showErrorSnackBar('Failed to install ADB key: $e');
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      }
    } finally {
      controller.dispose();
    }
  }

  void _showSetPortDialog() async {
    final controller = TextEditingController(text: adbStatus?.port ?? '5555');
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set ADB Port'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
              hintText: '5555',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Set'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        final port = int.tryParse(result);
        if (port == null || port < 1 || port > 65535) {
          if (mounted) context.showErrorSnackBar('Invalid port number');
          return;
        }
        setState(() => isLoading = true);
        try {
          await widget.repository.setPort(port);
          await _loadStatus();
          if (mounted) context.showSuccessSnackBar('ADB port set to $port');
        } catch (e) {
          if (mounted) context.showErrorSnackBar('Failed to set port: $e');
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = adbStatus?.isRunning == true;

    return ToolStatusCard(
      title: 'ADB',
      subtitle: 'Android Debug Bridge',
      icon: Icons.terminal,
      isLoading: isLoading,
      onRefresh: _loadStatus,
      statusItems: adbStatus == null
          ? []
          : [
              StatusItem(
                'Status',
                running ? 'Running' : 'Stopped',
                running ? Colors.green : Colors.orange,
              ),
              StatusItem('Port', adbStatus!.port),
            ],
      actions: [
        if (!running)
          ActionButton('Start', Icons.play_arrow, isLoading ? null : _startAdb),
        if (running)
          ActionButton('Stop', Icons.stop, isLoading ? null : _stopAdb),
        ActionButton('Install Key', Icons.vpn_key, isLoading ? null : _showAdbKeyDialog),
        ActionButton('Set Port', Icons.settings_ethernet, isLoading ? null : _showSetPortDialog),
        ActionButton(
          'Terminal',
          Icons.terminal,
          () => launchUrl(
            Uri.parse('${AppConfig.baseUrl}/terminal'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}
