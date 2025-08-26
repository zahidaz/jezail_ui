import 'package:flutter/material.dart';

import '../../../repositories/device_repository.dart';
import '../../widgets/common/snackbar_extensions.dart';
import '../../widgets/device/info_card.dart';

class StorageTab extends StatefulWidget {
  const StorageTab({super.key, required this.repository});

  final DeviceRepository repository;

  @override
  State<StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends State<StorageTab> {
  Map<String, dynamic> storageInfo = <String, dynamic>{};
  Map<String, dynamic> storageDetails = <String, dynamic>{};
  List<dynamic> mountPoints = [];
  bool loading = false;

  static final Map<int, String> _formatCache = <int, String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final [storageResult, detailsResult] = await Future.wait([
        widget.repository.getStorageInfo(),
        widget.repository.getStorageDetails(),
      ]);

      if (mounted) {
        final detailsData = detailsResult['data'] ?? <String, dynamic>{};
        setState(() {
          storageInfo = storageResult['data'] ?? <String, dynamic>{};
          storageDetails = Map<String, dynamic>.from(detailsData)
            ..remove('mountPoints');
          mountPoints = List<dynamic>.from(detailsData['mountPoints'] ?? []);
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to load storage information');
        setState(() => loading = false);
      }
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';

    return _formatCache[bytes] ??= () {
      const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
      var size = bytes.toDouble();
      var suffixIndex = 0;

      while (size >= 1024 && suffixIndex < suffixes.length - 1) {
        size /= 1024;
        suffixIndex++;
      }

      return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[suffixIndex]}';
    }();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).replaceAll(RegExp(r'([A-Z])'), ' \$1')}';
  }

  Widget _buildStorageSection(String title, Map<String, dynamic>? storage) {
    if (storage == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...[
          'totalSpace',
          'usedSpace',
          'freeSpace',
        ].map((key) => InfoRow(_capitalize(key), _formatBytes(storage[key]))),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        if (loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          _buildStorageOverview(),
          const SizedBox(height: 16),
          _buildStorageDetails(),
          const SizedBox(height: 16),
          _buildMountPoints(),
        ],
      ],
    ),
  );

  Widget _buildStorageOverview() => InfoCard(
    title: 'Storage Overview',
    icon: Icons.storage,
    actions: [
      IconButton(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
    ],
    children: [
      _buildStorageSection('Internal Storage', storageInfo['internal']),
      _buildStorageSection('External Storage', storageInfo['external']),
    ],
  );

  Widget _buildStorageDetails() => InfoCard(
    title: 'Storage Details',
    icon: Icons.folder,
    children: [
      ...storageDetails.entries.map((entry) {
        if (entry.value is Map<String, dynamic>) {
          final storage = entry.value as Map<String, dynamic>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              InfoRow('Path', storage['path']?.toString() ?? 'Unknown'),
              InfoRow('Total', _formatBytes(storage['totalSpace'])),
              InfoRow('Used', _formatBytes(storage['usedSpace'])),
              InfoRow('Free', _formatBytes(storage['freeSpace'])),
              InfoRow('Usable', _formatBytes(storage['usableSpace'])),
              InfoRow('Readable', storage['readable'] == true ? 'Yes' : 'No'),
              InfoRow('Writable', storage['writable'] == true ? 'Yes' : 'No'),
              const SizedBox(height: 12),
            ],
          );
        }
        return const SizedBox.shrink();
      }),
    ],
  );

  Widget _buildMountPoints() => _MountPointsCard(mountPoints: mountPoints);
}

class _MountPointsCard extends StatefulWidget {
  const _MountPointsCard({required this.mountPoints});

  final List<dynamic> mountPoints;

  @override
  State<_MountPointsCard> createState() => _MountPointsCardState();
}

class _MountPointsCardState extends State<_MountPointsCard> {
  late List<Map<String, dynamic>> _mountPoints;
  List<Map<String, dynamic>> _filtered = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _mountPoints = widget.mountPoints.cast<Map<String, dynamic>>();
    _filtered = _mountPoints;
  }

  @override
  void didUpdateWidget(_MountPointsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mountPoints != widget.mountPoints) {
      _mountPoints = widget.mountPoints.cast<Map<String, dynamic>>();
      _applyFilter();
    }
  }

  void _applyFilter() {
    if (_filter.isEmpty) {
      _filtered = _mountPoints;
    } else {
      final filterLower = _filter.toLowerCase();
      _filtered = _mountPoints
          .where(
            (mount) => mount.values.any(
              (value) => value.toString().toLowerCase().contains(filterLower),
            ),
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) => InfoCard(
    title: 'Mount Points (${_filtered.length}/${_mountPoints.length})',
    icon: Icons.folder_open,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: SearchBar(
          hintText: 'Filter mount points...',
          leading: const Icon(Icons.search),
          onChanged: (value) => setState(() {
            _filter = value;
            _applyFilter();
          }),
        ),
      ),

      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: ListView.separated(
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _MountPointCard(mount: _filtered[i]),
        ),
      ),
    ],
  );
}

class _MountPointCard extends StatelessWidget {
  const _MountPointCard({required this.mount});

  final Map<String, dynamic> mount;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mount['mountPoint']?.toString() ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            'Device: ${mount['device']?.toString() ?? 'Unknown'}',
            style: const TextStyle(fontSize: 10),
          ),
          Text(
            'FS: ${mount['fileSystem']?.toString() ?? 'Unknown'} | '
            'Options: ${mount['options']?.toString() ?? 'Unknown'}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    ),
  );
}
