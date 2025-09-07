enum AppTypeFilter { 
  all, 
  user, 
  system,
  launchable,
  running;

  String get displayName => switch (this) {
    AppTypeFilter.all => 'All',
    AppTypeFilter.user => 'User',
    AppTypeFilter.system => 'System',
    AppTypeFilter.launchable => 'Launchable',
    AppTypeFilter.running => 'Running',
  };
}

enum PackageAction { start, stop, details, uninstall }