import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jezail_ui/models/tab_info.dart';
import 'package:jezail_ui/services/service_registry.dart';
import 'package:jezail_ui/presentation/widgets/header.dart';
import 'package:jezail_ui/presentation/widgets/app_sidebar.dart';
import 'package:jezail_ui/presentation/tabs/files/files_tab.dart';
import 'package:jezail_ui/presentation/tabs/packages/packages_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.services});

  final ServiceRegistry services;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool sidebarCollapsed = false;

  void _onTabSelected(int index) {
    context.go(tabsConfig[index].path);
  }

  void _toggleSidebar() {
    setState(() {
      sidebarCollapsed = !sidebarCollapsed;
    });
  }

  Uri get _currentUri {
    final routerState = GoRouterState.of(context);
    return routerState.uri;
  }

  int get _currentTabIndex {
    final path = _currentUri.path;
    final index = tabsConfig.indexWhere((tab) => path.startsWith(tab.path));
    return index == -1 ? 0 : index;
  }

  Map<String, String> get _currentQueryParams {
    return _currentUri.queryParameters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Header(
            deviceService: widget.services.device,
            onToggleSidebar: _toggleSidebar,
          ),
          Expanded(
            child: Row(
              children: [
                AppSidebar(
                  collapsed: sidebarCollapsed,
                  selectedTab: _currentTabIndex,
                  tabs: tabsConfig.map((tab) => tab.title).toList(),
                  tabIcons: tabsConfig.map((tab) => tab.icon).toList(),
                  onTabSelected: _onTabSelected,
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: TabContainer(
                      currentTabIndex: _currentTabIndex,
                      services: widget.services,
                      queryParams: _currentQueryParams,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabContainer extends StatefulWidget {
  final int currentTabIndex;
  final ServiceRegistry services;
  final Map<String, String> queryParams;

  const TabContainer({
    super.key,
    required this.services,
    required this.currentTabIndex,
    required this.queryParams,
  });

  @override
  State<TabContainer> createState() => _TabContainerState();
}

class _TabContainerState extends State<TabContainer> {
  final Map<String, GlobalKey> _tabKeys = {};
  final Map<int, Widget> _cachedTabs = {};
  final Map<int, ValueNotifier<bool>> _isActiveNotifiers = {};
  String? _lastNavigatedFilePath;
  String? _lastNavigatedPackage;

  @override
  void initState() {
    super.initState();
    for (final tab in tabsConfig) {
      _tabKeys[tab.path] = GlobalKey();
    }
    _ensureTabBuilt(widget.currentTabIndex);
    _updateActiveNotifiers();
    _handleInitialQueryParams();
  }

  @override
  void didUpdateWidget(TabContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureTabBuilt(widget.currentTabIndex);
    _updateActiveNotifiers();
    _handleQueryParamNavigation(oldWidget);
  }

  @override
  void dispose() {
    for (final notifier in _isActiveNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _updateActiveNotifiers() {
    for (final entry in _isActiveNotifiers.entries) {
      entry.value.value = entry.key == widget.currentTabIndex;
    }
  }

  void _ensureTabBuilt(int index) {
    if (!_cachedTabs.containsKey(index)) {
      _isActiveNotifiers[index] = ValueNotifier(index == widget.currentTabIndex);
      _cachedTabs[index] = tabsConfig[index].builder(
        widget.services,
        key: _tabKeys[tabsConfig[index].path]!,
        isActiveNotifier: _isActiveNotifiers[index],
      );
    }
  }

  void _handleInitialQueryParams() {
    final currentTab = tabsConfig[widget.currentTabIndex];

    if (currentTab.path == '/files') {
      final path = widget.queryParams['path'];
      if (path != null && path.isNotEmpty) {
        _lastNavigatedFilePath = path;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = _tabKeys['/files']?.currentState;
          if (state is FilesTabState) {
            state.navigateToPath(path);
          }
        });
      }
    }

    if (currentTab.path == '/packages') {
      final packageName = widget.queryParams['package'];
      if (packageName != null && packageName.isNotEmpty) {
        _lastNavigatedPackage = packageName;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = _tabKeys['/packages']?.currentState;
          if (state is PackagesTabState) {
            state.navigateToPackageDetails(packageName);
          }
        });
      }
    }
  }

  void _handleQueryParamNavigation(TabContainer oldWidget) {
    final currentTab = tabsConfig[widget.currentTabIndex];
    final paramsChanged = oldWidget.queryParams.toString() != widget.queryParams.toString()
        || oldWidget.currentTabIndex != widget.currentTabIndex;

    if (!paramsChanged) return;

    if (currentTab.path == '/files') {
      final path = widget.queryParams['path'];
      if (path != null && path.isNotEmpty && path != _lastNavigatedFilePath) {
        _lastNavigatedFilePath = path;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = _tabKeys['/files']?.currentState;
          if (state is FilesTabState) {
            state.navigateToPath(path);
          }
        });
      }
    } else {
      _lastNavigatedFilePath = null;
    }

    if (currentTab.path == '/packages') {
      final packageName = widget.queryParams['package'];
      if (packageName != null && packageName.isNotEmpty && packageName != _lastNavigatedPackage) {
        _lastNavigatedPackage = packageName;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = _tabKeys['/packages']?.currentState;
          if (state is PackagesTabState) {
            state.navigateToPackageDetails(packageName);
          }
        });
      }
    } else {
      _lastNavigatedPackage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentTabIndex,
      children: List.generate(
        tabsConfig.length,
        (i) => _cachedTabs[i] ?? const SizedBox.shrink(),
      ),
    );
  }
}
