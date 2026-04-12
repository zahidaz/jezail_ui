import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jezail_ui/models/tab_info.dart';
import 'package:jezail_ui/services/service_registry.dart';
import 'package:jezail_ui/presentation/home_page.dart';

GoRouter createRouter(ServiceRegistry services) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (context, state) => tabsConfig.first.path),
      ShellRoute(
        builder: (context, state, child) => HomePage(services: services),
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
