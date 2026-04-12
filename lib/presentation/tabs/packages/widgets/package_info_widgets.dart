import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class PackageInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const PackageInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: '$label: $value'));
          context.showInfoSnackBar('$label copied to clipboard');
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class PackagePathRow extends StatelessWidget {
  final String label;
  final String? path;
  final void Function(String path) onOpenInFileExplorer;

  const PackagePathRow({
    super.key,
    required this.label,
    this.path,
    required this.onOpenInFileExplorer,
  });

  static String formatPath(String? path) {
    if (path == null || path.isEmpty) return 'Unknown';
    if (path.length > 40) {
      final parts = path.split('/');
      if (parts.length > 3) {
        return '.../${parts[parts.length - 2]}/${parts.last}';
      }
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return PackageInfoRow(label: label, value: 'Unknown');
    }

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onOpenInFileExplorer(path!),
                child: Text(
                  formatPath(path),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onOpenInFileExplorer(path!),
            child: Icon(Icons.folder_open, size: 14, color: cs.primary),
          ),
        ],
      ),
    );
  }
}

class PackageBadge extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final IconData icon;

  const PackageBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
