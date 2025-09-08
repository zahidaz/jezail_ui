import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/app_config.dart';
import 'package:jezail_ui/models/tab_info.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import 'package:jezail_ui/services/api_service.dart';
import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/core/log.dart';
import 'package:jezail_ui/presentation/widgets/header.dart';
import 'package:jezail_ui/presentation/widgets/app_sidebar.dart';

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

  runApp(const JezailApp());
}

class JezailApp extends StatelessWidget {
  const JezailApp({super.key});

  @override
  Widget build(BuildContext context) {
    BrowserContextMenu.disableContextMenu();

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _createRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  final Widget child;

  const HomePage({super.key, required this.child});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool sidebarCollapsed = false;
  late final ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService('${AppConfig.baseUrl}/api');
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
    final index = tabsConfig.indexWhere((tab) => location.startsWith(tab.path));
    return index == -1 ? 0 : index;
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
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: TabContainer(
                      currentTabIndex: _currentTabIndex,
                      apiService: apiService,
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
  final ApiService apiService;

  const TabContainer({
    super.key,
    required this.apiService,
    required this.currentTabIndex,
  });

  @override
  State<TabContainer> createState() => _TabContainerState();
}

class _TabContainerState extends State<TabContainer> {
  late final List<Widget> _tabWidgets;

  @override
  void initState() {
    super.initState();
    _tabWidgets = tabsConfig
        .map((tab) => tab.builder(widget.apiService))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(index: widget.currentTabIndex, children: _tabWidgets);
  }
}

GoRouter _createRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (context, state) => tabsConfig.first.path),
      ShellRoute(
        builder: (context, state, child) => HomePage(child: child),
        routes: tabsConfig.map((tab) {
          if (tab.hasSubroutes) {
            return GoRoute(
              path: tab.path,
              pageBuilder: (context, state) => NoTransitionPage(
                key: ValueKey(tab.path),
                child: const SizedBox.shrink(),
              ),
              routes: [
                GoRoute(
                  path: ':subpath(.*)',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: ValueKey('${tab.path}/sub'),
                    child: const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          } else {
            return GoRoute(
              path: tab.path,
              pageBuilder: (context, state) => NoTransitionPage(
                key: ValueKey(tab.path),
                child: const SizedBox.shrink(),
              ),
            );
          }
        }).toList(),
      ),
    ],
  );
}
