import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/info_card.dart';

class InfoTab extends StatefulWidget {
  const InfoTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<InfoTab> createState() => TabState();
}

class TabState extends State<InfoTab> with SingleTickerProviderStateMixin {
  Map<String, dynamic> deviceData = {};
  Map<String, dynamic> buildData = {};
  Map<String, dynamic> batteryData = {};
  Map<String, dynamic> cpuData = {};
  Map<String, dynamic> ramData = {};
  Map<String, dynamic> storageData = {};
  Map<String, dynamic> networkData = {};
  Map<String, dynamic> systemProps = {};
  String? selinuxStatus;
  
  String searchQuery = '';
  bool loading = false;
  Timer? debounce;
  late AnimationController anim;

  @override
  void initState() {
    super.initState();
    anim = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    anim.dispose();
    debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (loading) return;
    setState(() => loading = true);
    anim.repeat();
    
    try {
      final results = await Future.wait([
        widget.repository.getDeviceInfo(),
        widget.repository.getBuildInfo(),
        widget.repository.getBatteryInfo(),
        widget.repository.getCpuInfo(),
        widget.repository.getRamInfo(),
        widget.repository.getStorageInfo(),
        widget.repository.getNetworkInfo(),
        widget.repository.getSystemProperties(),
        widget.repository.getSelinuxStatus(),
      ]);

      if (mounted) {
        setState(() {
          deviceData = results[0]['data'] ?? {};
          buildData = results[1]['data'] ?? {};
          batteryData = results[2]['data'] ?? {};
          cpuData = results[3]['data'] ?? {};
          ramData = results[4]['data'] ?? {};
          storageData = results[5]['data'] ?? {};
          networkData = results[6]['data'] ?? {};
          systemProps = results[7]['data'] ?? {};
          selinuxStatus = results[8]['data']?.toString();
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load device information: $e');
    } finally {
      anim.stop();
      if (mounted) setState(() => loading = false);
    }
  }

  void _onSearchChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => searchQuery = value.toLowerCase());
    });
  }

  bool _matchesSearch(String text) {
    if (searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    context.showSuccessSnackBar('$label copied to clipboard');
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var suffixIndex = 0;
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[suffixIndex]}';
  }

  String _formatLabel(String key) {
    return key.replaceAllMapped(RegExp(r'(?=[A-Z])'), (m) => ' ')
        .trim()
        .split(' ')
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  Widget _buildSearchBar() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: SearchBar(
      hintText: 'Search device information...',
      leading: const Icon(Icons.search),
      trailing: [
        if (searchQuery.isNotEmpty)
          IconButton(
            onPressed: () {
              setState(() => searchQuery = '');
              debounce?.cancel();
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear search',
          ),
      ],
      onChanged: _onSearchChanged,
      constraints: const BoxConstraints(minHeight: 48),
    ),
  );

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Map<String, dynamic> data,
    Map<String, String Function(dynamic)>? formatters,
    List<String>? excludeKeys,
  }) {
    final filteredData = Map<String, dynamic>.from(data);
    excludeKeys?.forEach(filteredData.remove);

    final matchingItems = filteredData.entries
        .where((e) => _matchesSearch('$title ${e.key} ${e.value}'))
        .toList();

    if (matchingItems.isEmpty && searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return InfoCard(
      title: '$title${searchQuery.isNotEmpty && matchingItems.isNotEmpty ? ' (${matchingItems.length})' : ''}',
      icon: icon,
      children: matchingItems.map((entry) {
        final formatter = formatters?[entry.key];
        final value = formatter != null 
            ? formatter(entry.value)
            : entry.value?.toString() ?? 'Unknown';
        
        return InkWell(
          onTap: () => _copyToClipboard('${entry.key}: $value', _formatLabel(entry.key)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    _formatLabel(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                Icon(
                  Icons.copy,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSystemPropsSection() {
    final filteredProps = systemProps.entries
        .where((e) => _matchesSearch('system properties ${e.key} ${e.value}'))
        .toList();

    if (filteredProps.isEmpty && searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return InfoCard(
      title: 'System Properties${searchQuery.isNotEmpty && filteredProps.isNotEmpty ? ' (${filteredProps.length}/${systemProps.length})' : ' (${systemProps.length})'}',
      icon: Icons.settings_system_daydream,
      children: [
        if (filteredProps.isNotEmpty)
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(50)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: filteredProps.length,
              itemBuilder: (context, index) {
                final entry = filteredProps[index];
                return InkWell(
                  onTap: () => _copyToClipboard('${entry.key}=${entry.value}', 'Property'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 
                          ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(25)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.copy,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No matching system properties found'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading device information...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadAllData,
                icon: loading 
                    ? RotationTransition(turns: anim, child: const Icon(Icons.refresh))
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh all data',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildInfoSection(
                  title: 'Device Information',
                  icon: Icons.phone_android,
                  data: deviceData,
                  formatters: {
                    'isRooted': (v) => v == true ? 'Yes' : 'No',
                    'isDebuggable': (v) => v == true ? 'Yes' : 'No',
                    'is64Bit': (v) => v == true ? 'Yes' : 'No',
                    'supportedAbis': (v) => (v as List?)?.join(', ') ?? 'Unknown',
                    'totalRam': (v) => _formatBytes(v as int?),
                    'availableRam': (v) => _formatBytes(v as int?),
                    'batteryLevel': (v) => '${v ?? 0}%',
                    'isCharging': (v) => v == true ? 'Yes' : 'No',
                    'hasInternet': (v) => v == true ? 'Yes' : 'No',
                  },
                  excludeKeys: ['internalStorage'],
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Build Information',
                  icon: Icons.build,
                  data: buildData,
                  formatters: {
                    'supportedAbis': (v) => (v as List?)?.join(', ') ?? 'Unknown',
                    'isDebuggable': (v) => v == true ? 'Yes' : 'No',
                    'time': (v) => DateTime.fromMillisecondsSinceEpoch(v as int? ?? 0).toString(),
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Battery Information',
                  icon: Icons.battery_full,
                  data: batteryData,
                  formatters: {
                    'level': (v) => '${v ?? 0}%',
                    'temperature': (v) => '${((v as int? ?? 0) / 10).toStringAsFixed(1)}°C',
                    'voltage': (v) => '${v ?? 0}mV',
                    'present': (v) => v == true ? 'Yes' : 'No',
                    'plugged': (v) => v == true ? 'Yes' : 'No',
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'CPU Information',
                  icon: Icons.memory,
                  data: cpuData,
                  formatters: {
                    'is64Bit': (v) => v == true ? 'Yes' : 'No',
                    'maxFreq': (v) => '$v GHz',
                    'features': (v) => '${(v as List?)?.length ?? 0} features',
                    'supportedAbis': (v) => (v as List?)?.join(', ') ?? 'Unknown',
                  },
                  excludeKeys: ['features'], // Too long for main view
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Memory Information',
                  icon: Icons.memory_outlined,
                  data: ramData,
                  formatters: {
                    'totalMem': (v) => _formatBytes(v as int?),
                    'availMem': (v) => _formatBytes(v as int?),
                    'usedMem': (v) => _formatBytes(v as int?),
                    'memTotal': (v) => _formatBytes(v as int?),
                    'memFree': (v) => _formatBytes(v as int?),
                    'memAvailable': (v) => _formatBytes(v as int?),
                    'cached': (v) => _formatBytes(v as int?),
                    'buffers': (v) => _formatBytes(v as int?),
                    'swapTotal': (v) => _formatBytes(v as int?),
                    'swapFree': (v) => _formatBytes(v as int?),
                    'shmem': (v) => _formatBytes(v as int?),
                    'threshold': (v) => _formatBytes(v as int?),
                    'lowMemory': (v) => v == true ? 'Yes' : 'No',
                    'isLowRamDevice': (v) => v == true ? 'Yes' : 'No',
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Storage Information',
                  icon: Icons.storage,
                  data: {...storageData, if (deviceData['internalStorage'] != null) 'deviceInternal': deviceData['internalStorage']},
                  formatters: {
                    'totalSpace': (v) => _formatBytes(v as int?),
                    'freeSpace': (v) => _formatBytes(v as int?),
                    'usedSpace': (v) => _formatBytes(v as int?),
                    'usableSpace': (v) => _formatBytes(v as int?),
                    'writable': (v) => v == true ? 'Yes' : 'No',
                    'readable': (v) => v == true ? 'Yes' : 'No',
                    'exists': (v) => v == true ? 'Yes' : 'No',
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  title: 'Network Information',
                  icon: Icons.network_check,
                  data: {
                    ...?networkData['activeConnection'],
                    ...?networkData['wifi'],
                    ...?networkData['cellular'],
                    if (networkData['dhcp'] != null) 'dhcp': networkData['dhcp'].toString(),
                  },
                  formatters: {
                    'hasInternet': (v) => v == true ? 'Yes' : 'No',
                    'hasWifi': (v) => v == true ? 'Yes' : 'No',
                    'hasCellular': (v) => v == true ? 'Yes' : 'No',
                    'hasEthernet': (v) => v == true ? 'Yes' : 'No',
                    'validated': (v) => v == true ? 'Yes' : 'No',
                    'rssi': (v) => '$v dBm',
                    'linkSpeed': (v) => '$v Mbps',
                    'txLinkSpeed': (v) => '$v Mbps',
                    'rxLinkSpeed': (v) => '$v Mbps',
                    'frequency': (v) => '$v MHz',
                    'isNetworkRoaming': (v) => v == true ? 'Yes' : 'No',
                    'isDataEnabled': (v) => v == true ? 'Yes' : 'No',
                  },
                  excludeKeys: ['interfaces', 'routes', 'arp', 'linkProperties'],
                ),
                const SizedBox(height: 16),
                if (selinuxStatus != null)
                  InfoCard(
                    title: 'Security',
                    icon: Icons.security,
                    children: [
                      InkWell(
                        onTap: () => _copyToClipboard('SELinux: $selinuxStatus', 'SELinux Status'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 140, child: Text('SELinux Status', style: TextStyle(fontWeight: FontWeight.w500))),
                              Expanded(child: Text(selinuxStatus!, style: const TextStyle(fontFamily: 'monospace'))),
                              Icon(Icons.copy, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                _buildSystemPropsSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}