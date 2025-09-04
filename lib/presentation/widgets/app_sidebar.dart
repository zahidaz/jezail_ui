import 'package:flutter/material.dart';
import 'package:jezail_ui/presentation/widgets/sidebar_item.dart';

class AppSidebar extends StatelessWidget {
  final bool collapsed;
  final int selectedTab;
  final List<String> tabs;
  final List<IconData> tabIcons;
  final Function(int) onTabSelected;

  const AppSidebar({
    super.key,
    required this.collapsed,
    required this.selectedTab,
    required this.tabs,
    required this.tabIcons,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: collapsed ? 64 : 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withAlpha(50),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 8 : 8,
                vertical: 4,
              ),
              itemCount: tabs.length,
              itemBuilder: (context, index) => SidebarItem(
                icon: tabIcons[index],
                title: tabs[index],
                isSelected: selectedTab == index,
                isCollapsed: collapsed,
                onTap: () => onTabSelected(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}