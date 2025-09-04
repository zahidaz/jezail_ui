import 'package:flutter/material.dart';

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                  ? cs.primaryContainer.withAlpha(128)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(
                      color: cs.primary.withAlpha(50),
                      width: 1,
                    )
                  : null,
            ),
            child: isCollapsed 
                ? Center(
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected 
                          ? cs.primary 
                          : cs.onSurfaceVariant,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected 
                            ? cs.primary 
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected 
                                ? cs.primary
                                : cs.onSurface,
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}