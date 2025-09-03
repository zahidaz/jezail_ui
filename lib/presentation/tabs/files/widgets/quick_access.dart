import 'package:flutter/material.dart';

class QuickAccess extends StatelessWidget {
  const QuickAccess({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  final String currentPath;
  final void Function(String path) onNavigate;

  static const List<QuickAccessItem> _quickAccessItems = [
    QuickAccessItem(
      path: '/data/local/tmp',
      name: 'Temp',
      icon: Icons.folder_special,
      description: 'Temporary files directory',
    ),
    QuickAccessItem(
      path: '/sdcard',
      name: 'sdcard',
      icon: Icons.sd_card,
      description: 'Internal device storage',
    ),
    QuickAccessItem(
      path: '/',
      name: 'Root',
      icon: Icons.storage,
      description: 'System root directory',
    ),
    QuickAccessItem(
      path: '/data/data',
      name: 'App Data',
      icon: Icons.apps,
      description: 'Application data directory',
    ),
    QuickAccessItem(
      path: '/data',
      name: 'Data',
      icon: Icons.storage,
      description: 'Data directory',
    ),
    QuickAccessItem(
      path: '/system',
      name: 'System',
      icon: Icons.settings,
      description: 'System files and binaries',
    ),
    QuickAccessItem(
      path: '/system/app',
      name: 'System App',
      icon: Icons.android,
      description: 'System applications',
    ),
    QuickAccessItem(
      path: '/vendor',
      name: 'Vendor',
      icon: Icons.business,
      description: 'Vendor-specific files',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 6,
          runSpacing: 6,
          children: _quickAccessItems
              .map((item) => _buildQuickAccessChip(context, theme, item))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildQuickAccessChip(BuildContext context, ThemeData theme, QuickAccessItem item) {
    final isCurrentPath = currentPath == item.path;
    
    return Tooltip(
      message: '${item.description}\nPath: ${item.path}',
      child: FilterChip(
        selected: isCurrentPath,
        onSelected: (_) {
          if (!isCurrentPath) {
            onNavigate(item.path);
          }
        },
        label: Text(
          item.name,
          style: const TextStyle(fontSize: 12),
        ),
        avatar: Icon(item.icon, size: 14),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        showCheckmark: false,
        selectedColor: theme.colorScheme.primaryContainer,
        backgroundColor: theme.colorScheme.surface,
      ),
    );
  }
}

class QuickAccessItem {
  const QuickAccessItem({
    required this.path,
    required this.name,
    required this.icon,
    required this.description,
  });

  final String path;
  final String name;
  final IconData icon;
  final String description;
}