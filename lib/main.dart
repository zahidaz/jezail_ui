import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'models/tab_info.dart';
import 'services/api_service.dart';
import 'services/device_service.dart';
import 'services/file_service.dart';
import 'repositories/files_repository.dart';
import 'presentation/tabs/files/files_tab.dart';
import 'services/package_service.dart';
import 'repositories/package_repository.dart';
import 'presentation/tabs/packages/packages_tab.dart';
import 'utils/log.dart';
import 'presentation/widgets/header.dart';

const appName = "JEZAIL";

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => tabsConfig.first.path,
    ),
    ShellRoute(
      builder: (context, state, child) => MyHomePage(child: child),
      routes: [
        ...tabsConfig.where((tab) => tab.path != '/packages').map((tab) => GoRoute(
          path: tab.path,
          pageBuilder: (context, state) => NoTransitionPage(
            key: ValueKey(tab.path),
            child: const SizedBox(),
          ),
        )),
        GoRoute(
          path: '/packages',
          pageBuilder: (context, state) => NoTransitionPage(
            key: const ValueKey('/packages'),
            child: const SizedBox(),
          ),
        ),
        GoRoute(
          path: '/packages/details',
          pageBuilder: (context, state) => NoTransitionPage(
            key: const ValueKey('/packages'),
            child: const SizedBox(),
          ),
        ),
      ],
    ),
  ],
);

void main() {
  Log.configure(
    level: kDebugMode ? Level.debug : Level.info,
    printer: PrettyPrinter(
      methodCount: kDebugMode ? 2 : 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      noBoxingByDefault: kIsWeb,
    ),
  );
  
  runApp(const MyWebApp());
}

class MyWebApp extends StatelessWidget {
  const MyWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    BrowserContextMenu.disableContextMenu();
    return MaterialApp.router(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Widget child;
  
  const MyHomePage({super.key, required this.child});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool sidebarCollapsed = false;
  late final ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService('http://localhost:8080/api');
  }

  void _onTabSelected(int index) {
    context.go(tabsConfig[index].path);
  }

  void _toggleSidebar() {
    setState(() {
      sidebarCollapsed = !sidebarCollapsed;
    });
  }

  int get _currentTabIndex {
    final location = GoRouterState.of(context).fullPath ?? '';
    final path = location.split('?').first;
    
    // Handle packages sub-routes
    if (path.startsWith('/packages')) {
      return tabsConfig.indexWhere((tab) => tab.path == '/packages');
    }
    
    final index = tabsConfig.indexWhere((tab) => tab.path == path);
    return index == -1 ? 0 : index;
  }

  String? get _currentFilePath {
    final routerState = GoRouterState.of(context);
    if (routerState.fullPath?.startsWith('/files') == true) {
      return routerState.uri.queryParameters['path'];
    }
    return null;
  }

  String? get _currentPackageName {
    final routerState = GoRouterState.of(context);
    if (routerState.fullPath?.startsWith('/packages/details') == true) {
      return routerState.uri.queryParameters['package'];
    }
    return null;
  }

  bool get _isPackageDetailsView {
    final location = GoRouterState.of(context).fullPath ?? '';
    return location.startsWith('/packages/details');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            deviceService: DeviceService(apiService),
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
                MainContent(
                  child: TabContainer(
                    currentTabIndex: _currentTabIndex,
                    apiService: apiService,
                    initialFilePath: _currentFilePath,
                    initialPackageName: _currentPackageName,
                    isPackageDetailsView: _isPackageDetailsView,
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
  final ApiService apiService;
  final String? initialFilePath;
  final String? initialPackageName;
  final bool isPackageDetailsView;
  
  const TabContainer({
    super.key, 
    required this.currentTabIndex,
    required this.apiService,
    this.initialFilePath,
    this.initialPackageName,
    required this.isPackageDetailsView,
  });

  @override
  State<TabContainer> createState() => _TabContainerState();
}

class _TabContainerState extends State<TabContainer> {
  late final List<Widget> _tabWidgets;
  final GlobalKey<State<FilesTab>> _filesTabKey = GlobalKey<State<FilesTab>>();
  final GlobalKey<State<PackagesTab>> _packagesTabKey = GlobalKey<State<PackagesTab>>();

  @override
  void initState() {
    super.initState();
    _tabWidgets = tabsConfig.map((tab) {
      if (tab.path == '/files') {
        return FilesTab(
          key: _filesTabKey,
          repository: FileRepository(FilesService(widget.apiService)),
        );
      }
      if (tab.path == '/packages') {
        return PackagesTab(
          key: _packagesTabKey,
          packageRepository: PackageRepository(PackageService(widget.apiService)),
        );
      }
      return tab.builder(widget.apiService);
    }).toList();

    // Handle initial navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Handle files tab initial path
      if (widget.initialFilePath != null &&
          widget.currentTabIndex == tabsConfig.indexWhere((tab) => tab.path == '/files')) {
        final state = _filesTabKey.currentState;
        if (state is FilesTabState) {
          state.navigateToPath(widget.initialFilePath!);
        }
      }
      
      // Handle packages tab initial state
      if (widget.currentTabIndex == tabsConfig.indexWhere((tab) => tab.path == '/packages')) {
        final state = _packagesTabKey.currentState;
        if (state is PackagesTabState) {
          if (widget.isPackageDetailsView && widget.initialPackageName != null) {
            state.navigateToPackageDetails(widget.initialPackageName!);
          }
        }
      }
    });
  }

  @override
  void didUpdateWidget(TabContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle files tab path changes
    if (widget.initialFilePath != oldWidget.initialFilePath && 
        widget.initialFilePath != null &&
        widget.currentTabIndex == tabsConfig.indexWhere((tab) => tab.path == '/files')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = _filesTabKey.currentState;
        if (state is FilesTabState) {
          state.navigateToPath(widget.initialFilePath!);
        }
      });
    }
    
    // Handle packages tab state changes
    if ((widget.initialPackageName != oldWidget.initialPackageName ||
         widget.isPackageDetailsView != oldWidget.isPackageDetailsView) &&
        widget.currentTabIndex == tabsConfig.indexWhere((tab) => tab.path == '/packages')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = _packagesTabKey.currentState;
        if (state is PackagesTabState) {
          if (widget.isPackageDetailsView && widget.initialPackageName != null) {
            state.navigateToPackageDetails(widget.initialPackageName!);
          } else if (!widget.isPackageDetailsView) {
            state.navigateToPackageList();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentTabIndex,
      children: _tabWidgets,
    );
  }
}

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 56 : 180,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...List.generate(
            tabs.length,
            (index) => SidebarItem(
              icon: tabIcons[index],
              title: tabs[index],
              isSelected: selectedTab == index,
              isCollapsed: collapsed,
              onTap: () => onTabSelected(index),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: isCollapsed ? null : Text(title),
      selected: isSelected,
      onTap: onTap,
    );
  }
}

class MainContent extends StatelessWidget {
  final Widget child;

  const MainContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: child,
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  final DeviceService deviceService;
  final VoidCallback? onToggleSidebar;

  const AppHeader({
    super.key,
    required this.deviceService,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Header(
      deviceService: deviceService,
      onToggleSidebar: onToggleSidebar,
    );
  }
}
