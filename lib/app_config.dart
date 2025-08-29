import 'package:flutter/foundation.dart';

class AppConfig {
  static const _envBaseUrl = String.fromEnvironment(
    'JEZAIL_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl => _envBaseUrl.isNotEmpty
      ? _envBaseUrl
      : kReleaseMode
      ? Uri.base.origin
      : 'http://localhost:8080';

  static const appName = "JEZAIL";
}
