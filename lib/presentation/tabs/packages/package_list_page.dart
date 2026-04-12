import 'package:flutter/material.dart';
import 'package:jezail_ui/models/packages/package_info.dart';
import 'package:jezail_ui/core/enums/package_enums.dart';

typedef PackageListState = ({
  List<PackageInfo> packages,
  bool isLoading,
  String? error,
  String searchQuery,
  AppTypeFilter filter,
});

class PackageListPage extends StatelessWidget {
  const PackageListPage({
    super.key,
    required this.state,
    required this.filteredPackages,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onInstallApk,
    required this.onPackageAction,
  });

  final PackageListState state;
  final List<PackageInfo> filteredPackages;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AppTypeFilter> onFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onInstallApk;
  final Function(PackageAction, PackageInfo) onPackageAction;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error case final error?) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withAlpha(25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search packages...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: TextStyle(
                              color: cs.onSurfaceVariant.withAlpha(150),
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh, color: cs.primary, size: 20),
                tooltip: 'Refresh packages',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outline.withAlpha(25)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...() {
                final counts = _getFilterCounts();
                return AppTypeFilter.values.map((f) {
                final isSelected = f == state.filter;
                final count = counts[f] ?? 0;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (_) => onFilterChanged(f),
                  label: Text(
                    isSelected ? '${f.displayName} ($count)' : f.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  avatar: Icon(_getFilterIcon(f), size: 14),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  showCheckmark: false,
                );
              });
              }(),
              FilledButton.icon(
                onPressed: onInstallApk,
                icon: const Icon(Icons.file_upload, size: 16),
                label: const Text(
                  'Install APK',
                  style: TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredPackages.isEmpty
              ? const Center(child: Text('No packages found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPackages.length,
                  itemBuilder: (_, i) => PackageListItem(
                    key: ValueKey(filteredPackages[i].packageName),
                    pkg: filteredPackages[i],
                    onAction: onPackageAction,
                    isEven: i % 2 == 0,
                  ),
                ),
        ),
      ],
    );
  }

  Map<AppTypeFilter, int> _getFilterCounts() {
    final counts = {for (final f in AppTypeFilter.values) f: 0};
    final query = state.searchQuery.toLowerCase();
    for (final pkg in state.packages) {
      final matchesSearch = query.isEmpty ||
          pkg.name.toLowerCase().contains(query) ||
          pkg.packageName.toLowerCase().contains(query);
      if (!matchesSearch) continue;
      counts[AppTypeFilter.all] = counts[AppTypeFilter.all]! + 1;
      if (!pkg.isSystemApp) counts[AppTypeFilter.user] = counts[AppTypeFilter.user]! + 1;
      if (pkg.isSystemApp) counts[AppTypeFilter.system] = counts[AppTypeFilter.system]! + 1;
      if (pkg.canLaunch) counts[AppTypeFilter.launchable] = counts[AppTypeFilter.launchable]! + 1;
      if (pkg.isRunning) counts[AppTypeFilter.running] = counts[AppTypeFilter.running]! + 1;
    }
    return counts;
  }

  IconData _getFilterIcon(AppTypeFilter filter) => switch (filter) {
    AppTypeFilter.all => Icons.apps,
    AppTypeFilter.user => Icons.person,
    AppTypeFilter.system => Icons.settings,
    AppTypeFilter.launchable => Icons.touch_app,
    AppTypeFilter.running => Icons.play_circle,
  };
}

class PackageListItem extends StatelessWidget {
  const PackageListItem({
    super.key,
    required this.pkg,
    required this.onAction,
    required this.isEven,
  });

  final PackageInfo pkg;
  final Function(PackageAction, PackageInfo) onAction;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Material(
        color: isEven ? cs.surface : cs.surfaceContainerHighest.withAlpha(64),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onAction(PackageAction.details, pkg),
          borderRadius: BorderRadius.circular(8),
          hoverColor: cs.primaryContainer,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  PackageIcon(pkg: pkg, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pkg.packageName,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (pkg.version != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            'v${pkg.version}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant.withAlpha(150),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (pkg.isRunning && !pkg.canLaunch) ...[
                    _RunningBadge(),
                    const SizedBox(width: 8),
                  ],
                  PackageActionButtons(package: pkg, onAction: onAction),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PackageActionButtons extends StatefulWidget {
  const PackageActionButtons({
    super.key,
    required this.package,
    required this.onAction,
  });

  final PackageInfo package;
  final Function(PackageAction, PackageInfo) onAction;

  @override
  State<PackageActionButtons> createState() => _PackageActionButtonsState();
}

class _PackageActionButtonsState extends State<PackageActionButtons> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    final action = widget.package.isRunning ? PackageAction.stop : PackageAction.start;
    try {
      await widget.onAction(action, widget.package);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.package.canLaunch) return const SizedBox.shrink();

    final isRunning = widget.package.isRunning;
    final color = isRunning ? Colors.red : Colors.green;
    final icon = isRunning ? Icons.stop : Icons.play_arrow;
    final text = isRunning ? 'Stop' : 'Start';

    return FilledButton.tonal(
      onPressed: _loading ? null : _handleTap,
      style: FilledButton.styleFrom(
        backgroundColor: color.withAlpha(25),
        minimumSize: const Size(60, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _loading
          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
              ],
            ),
    );
  }
}

class _RunningBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'Running',
          style: TextStyle(
            color: Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class PackageIcon extends StatelessWidget {
  const PackageIcon({super.key, required this.pkg, required this.radius});

  final PackageInfo pkg;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = pkg.iconBytes;
    if (bytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }
    return CircleAvatar(radius: radius, child: const Icon(Icons.android));
  }
}
