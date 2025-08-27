import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/info_card.dart';

class AdvancedTab extends StatefulWidget {
  const AdvancedTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<AdvancedTab> createState() => _AdvancedTabState();
}

class _AdvancedTabState extends State<AdvancedTab> {
  String? clipboardContent;
  Map<String, dynamic>? cpuInfo;
  Map<String, dynamic>? networkDetails;
  bool loading = false;
  final clipboardController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    clipboardController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        widget.repository.getClipboard(),
        widget.repository.getCpuInfo(),
        widget.repository.getNetworkInfo(),
      ]);
      if (mounted) {
        setState(() {
          clipboardContent = results[0] as String?;
          cpuInfo = (results[1] as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
          networkDetails = (results[2] as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
          clipboardController.text = (results[0] as String?) ?? '';
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load data: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setClipboard() async {
    try {
      await widget.repository.setClipboard(clipboardController.text);
      await _refreshClipboard();
      if (mounted) context.showSuccessSnackBar('Clipboard updated');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to set clipboard: $e');
    }
  }

  Future<void> _clearClipboard() async {
    try {
      await widget.repository.clearClipboard();
      await _refreshClipboard();
      clipboardController.clear();
      if (mounted) context.showSuccessSnackBar('Clipboard cleared');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to clear clipboard: $e');
    }
  }

  Future<void> _refreshClipboard() async {
    try {
      final content = await widget.repository.getClipboard();
      if (mounted) {
        setState(() {
          clipboardContent = content;
          clipboardController.text = content ?? '';
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to refresh clipboard: $e');
    }
  }

  Future<void> _downloadScreenshot() async {
    try {
      await widget.repository.downloadScreenshot();
      if (mounted) context.showSuccessSnackBar('Screenshot downloaded');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to download screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildScreenshotCard(),
          const SizedBox(height: 16),
          _buildClipboardCard(),
          const SizedBox(height: 16),
          _buildCpuFeaturesCard(),
          const SizedBox(height: 16),
          _buildNetworkDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildScreenshotCard() => InfoCard(
    title: 'Screenshot',
    icon: Icons.screenshot,
    children: [
      InfoRow('Action', 'Download device screenshot'),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: _downloadScreenshot,
        icon: const Icon(Icons.download),
        label: const Text('Download Screenshot'),
      ),
    ],
  );

  Widget _buildClipboardCard() => InfoCard(
    title: 'Clipboard Management',
    icon: Icons.content_paste,
    actions: [
      IconButton(
        onPressed: _refreshClipboard,
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
    ],
    children: [
      InfoRow('Current Content', clipboardContent?.isEmpty == true ? 'Empty' : clipboardContent ?? 'Unknown'),
      const SizedBox(height: 12),
      TextField(
        controller: clipboardController,
        decoration: const InputDecoration(
          labelText: 'New clipboard content',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: _setClipboard,
            icon: const Icon(Icons.content_paste),
            label: const Text('Set Clipboard'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _clearClipboard,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Clipboard'),
          ),
        ],
      ),
    ],
  );

  Widget _buildCpuFeaturesCard() => InfoCard(
    title: 'CPU Features',
    icon: Icons.memory,
    children: [
      InfoRow('Architecture', cpuInfo?['architecture']?.toString() ?? 'Unknown'),
      InfoRow('Cores', cpuInfo?['cores']?.toString() ?? 'Unknown'),
      InfoRow('Max Frequency', '${cpuInfo?['maxFreq']} GHz'),
      InfoRow('Processor', cpuInfo?['processor']?.toString() ?? 'Unknown'),
      const SizedBox(height: 8),
      const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      if (cpuInfo?['features'] is List)
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: (cpuInfo!['features'] as List)
              .map<Widget>((feature) => Chip(
                    label: Text(feature.toString(), style: const TextStyle(fontSize: 10)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        )
      else
        const Text('No features available', style: TextStyle(fontSize: 12)),
    ],
  );

  Widget _buildNetworkDetailsCard() => InfoCard(
    title: 'Network Details',
    icon: Icons.network_check,
    children: [
      const Text('DHCP Information', style: TextStyle(fontWeight: FontWeight.bold)),
      InfoRow('IP Address', networkDetails?['dhcp']?['ipAddress']?.toString() ?? 'Unknown'),
      InfoRow('Gateway', networkDetails?['dhcp']?['gateway']?.toString() ?? 'Unknown'),
      InfoRow('DNS Servers', (networkDetails?['dhcp']?['dnsServers'] as List?)?.join(', ') ?? 'Unknown'),
      InfoRow('MTU', networkDetails?['dhcp']?['mtu']?.toString() ?? 'Unknown'),
      const SizedBox(height: 12),
      const Text('Link Properties', style: TextStyle(fontWeight: FontWeight.bold)),
      InfoRow('Interface', networkDetails?['linkProperties']?['interfaceName']?.toString() ?? 'Unknown'),
      InfoRow('Link Addresses', (networkDetails?['linkProperties']?['linkAddresses'] as List?)?.length.toString() ?? '0'),
      InfoRow('Routes', (networkDetails?['linkProperties']?['routes'] as List?)?.length.toString() ?? '0'),
      InfoRow('DNS Servers', (networkDetails?['linkProperties']?['dnsServers'] as List?)?.join(', ') ?? 'Unknown'),
      const SizedBox(height: 12),
      const Text('Network Interfaces', style: TextStyle(fontWeight: FontWeight.bold)),
      InfoRow('Total Interfaces', (networkDetails?['interfaces'] as List?)?.length.toString() ?? '0'),
      const SizedBox(height: 8),
      if (networkDetails?['interfaces'] is List)
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(50)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: (networkDetails!['interfaces'] as List).length,
            itemBuilder: (context, index) {
              final interface = (networkDetails!['interfaces'] as List)[index].toString();
              return ListTile(
                dense: true,
                title: Text(
                  interface.split('\n').first,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: interface));
                  context.showSuccessSnackBar('Interface info copied');
                },
                trailing: const Icon(Icons.copy, size: 16),
              );
            },
          ),
        ),
    ],
  );
}