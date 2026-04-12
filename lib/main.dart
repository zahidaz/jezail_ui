import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/app_config.dart';
import 'package:jezail_ui/services/api_service.dart';
import 'package:jezail_ui/services/service_registry.dart';
import 'package:jezail_ui/core/log.dart';
import 'package:jezail_ui/presentation/router.dart';
import 'package:logger/logger.dart';

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

  WidgetsFlutterBinding.ensureInitialized();
  BrowserContextMenu.disableContextMenu();
  runApp(const JezailApp());
}

class JezailApp extends StatefulWidget {
  const JezailApp({super.key});

  @override
  State<JezailApp> createState() => _JezailAppState();
}

class ThemeModeNotifier extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeModeNotifier({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeModeNotifier>()!.notifier!;
  }
}

class _JezailAppState extends State<JezailApp> {
  late final ServiceRegistry _services;
  late final _router = createRouter(_services);
  final _themeMode = ValueNotifier(ThemeMode.system);

  @override
  void initState() {
    super.initState();
    final api = ApiService('${AppConfig.baseUrl}/api');
    _services = ServiceRegistry(api);
  }

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeNotifier(
      notifier: _themeMode,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, mode, _) => MaterialApp.router(
          title: AppConfig.appName,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
