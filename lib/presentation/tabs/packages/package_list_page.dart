import 'dart:convert';
import 'package:jezail_ui/models/packages/package_actions.dart';
import 'package:jezail_ui/models/packages/package_info.dart';
import 'package:flutter/material.dart';
import 'package:jezail_ui/core/enums/package_enums.dart';

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

  final PackageState state;
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or package',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: AppTypeFilter.values.map((f) => f == state.filter).toList(),
                onPressed: (idx) => onFilterChanged(AppTypeFilter.values[idx]),
                children: ['All', 'User', 'System']
                    .map((text) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(text),
                        ))
                    .toList(),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onInstallApk,
                icon: const Icon(Icons.file_upload),
                label: const Text('Install APK'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredPackages.isEmpty
              ? const Center(child: Text('No packages found'))
              : ListView.builder(
                  itemCount: filteredPackages.length,
                  itemBuilder: (_, i) => PackageListItem(
                    key: ValueKey(filteredPackages[i].packageName),
                    pkg: filteredPackages[i],
                    onAction: onPackageAction,
                  ),
                ),
        ),
      ],
    );
  }
}

class PackageListItem extends StatelessWidget {
  const PackageListItem({super.key, required this.pkg, required this.onAction});

  final PackageInfo pkg;
  final Function(PackageAction, PackageInfo) onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: PackageIcon(pkg: pkg, radius: 24),
        title: Text(pkg.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pkg.packageName),
            if (pkg.version != null) 
              Text('v${pkg.version}', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pkg.isRunning)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Running', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            const SizedBox(width: 8),
            PackageActionButtons(package: pkg, onAction: onAction),
          ],
        ),
      ),
    );
  }
}

class PackageActionButtons extends StatelessWidget {
  const PackageActionButtons({super.key, required this.package, required this.onAction});

  final PackageInfo package;
  final Function(PackageAction, PackageInfo) onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (package.canLaunch)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Start',
            onPressed: () => onAction(PackageAction.start, package),
          ),
        IconButton(
          icon: const Icon(Icons.stop),
          tooltip: 'Stop',
          onPressed: () => onAction(PackageAction.stop, package),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Details',
          onPressed: () => onAction(PackageAction.details, package),
        ),
        if (!package.isSystemApp)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Uninstall',
            onPressed: () => onAction(PackageAction.uninstall, package),
          ),
      ],
    );
  }
}

class PackageIcon extends StatelessWidget {
  const PackageIcon({super.key, required this.pkg, required this.radius});

  final PackageInfo pkg;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (pkg.iconBase64.isNotEmpty) {
      try {
        final iconData = pkg.iconBase64.contains(',') 
            ? pkg.iconBase64.split(',').last 
            : pkg.iconBase64;
        final bytes = base64Decode(iconData);
        return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes));
      } catch (e) {
        // Invalid base64 data, fall through to default icon
      }
    }
    return CircleAvatar(radius: radius, child: const Icon(Icons.android));
  }
}