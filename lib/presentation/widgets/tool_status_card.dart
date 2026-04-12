import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusItem {
  final String label;
  final String value;
  final Color? color;
  final bool isPath;
  final VoidCallback? onNavigate;

  const StatusItem(this.label, this.value, [this.color, this.isPath = false, this.onNavigate]);
}

class ActionButton {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const ActionButton(this.label, this.icon, this.onPressed);
}

class ToolStatusCard extends StatelessWidget {
  const ToolStatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.statusItems,
    required this.actions,
    this.isLoading = false,
    this.onRefresh,
    this.showLoadingIndicator = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<StatusItem> statusItems;
  final List<ActionButton> actions;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(subtitle),
                    trailing: IconButton(
                      onPressed: isLoading ? null : onRefresh,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh $title status',
                    ),
                  ),
                  if (showLoadingIndicator && isLoading && statusItems.isEmpty) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                  ],
                  if (statusItems.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...statusItems.map((item) => _StatusRow(item: item)),
                    const SizedBox(height: 16),
                  ],
                  if (actions.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: actions
                          .map(
                            (action) => ActionChip(
                              avatar: Icon(action.icon, size: 18),
                              label: Text(action.label),
                              onPressed: action.onPressed,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.item});

  final StatusItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '${item.label}:',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: item.isPath
                ? _PathValue(item: item)
                : Text(
                    item.value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.color ??
                              Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PathValue extends StatelessWidget {
  const _PathValue({required this.item});

  final StatusItem item;

  void _copyPath(BuildContext context) {
    Clipboard.setData(ClipboardData(text: item.value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Path copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Flexible(
          child: GestureDetector(
            onTap: () => _copyPath(context),
            child: Text(
              item.value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _copyPath(context),
          child: Icon(Icons.copy, size: 16, color: cs.primary),
        ),
        if (item.onNavigate != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: item.onNavigate,
            child: Icon(Icons.folder_open, size: 16, color: cs.primary),
          ),
        ],
      ],
    );
  }
}
