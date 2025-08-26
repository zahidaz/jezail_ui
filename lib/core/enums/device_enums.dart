import 'package:flutter/material.dart';

enum ServiceStatus { running, stopped, unknown }

enum LogType { main, system, kernel, radio, crash, events }

extension ServiceStatusExtension on ServiceStatus {
  String get displayName => switch (this) {
    ServiceStatus.running => 'Running',
    ServiceStatus.stopped => 'Stopped',
    ServiceStatus.unknown => 'Unknown',
  };

  static ServiceStatus fromString(String? status) =>
      switch (status?.toLowerCase()) {
        'running' => ServiceStatus.running,
        'stopped' => ServiceStatus.stopped,
        _ => ServiceStatus.unknown,
      };
}

extension LogTypeExtension on LogType {
  String get displayName => switch (this) {
    LogType.main => 'Main',
    LogType.system => 'System',
    LogType.kernel => 'Kernel',
    LogType.radio => 'Radio',
    LogType.crash => 'Crash',
    LogType.events => 'Events',
  };

  IconData get icon => switch (this) {
    LogType.main => Icons.list_alt,
    LogType.system => Icons.settings,
    LogType.kernel => Icons.memory,
    LogType.radio => Icons.wifi,
    LogType.crash => Icons.error,
    LogType.events => Icons.event,
  };
}