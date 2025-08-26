import 'package:flutter/material.dart';

enum BatteryLevel { critical, low, medium, high, full }

extension BatteryLevelExtension on BatteryLevel {
  String get displayName {
    switch (this) {
      case BatteryLevel.critical:
        return 'Critical';
      case BatteryLevel.low:
        return 'Low';
      case BatteryLevel.medium:
        return 'Medium';
      case BatteryLevel.high:
        return 'High';
      case BatteryLevel.full:
        return 'Full';
    }
  }

  IconData get icon => switch (this) {
    BatteryLevel.critical => Icons.battery_1_bar,
    BatteryLevel.low => Icons.battery_2_bar,
    BatteryLevel.medium => Icons.battery_3_bar,
    BatteryLevel.high => Icons.battery_5_bar,
    BatteryLevel.full => Icons.battery_full,
  };

  Color get color => switch (this) {
    BatteryLevel.critical => Colors.red,
    BatteryLevel.low => Colors.orange,
    _ => Colors.white,
  };
  
  static BatteryLevel fromPercent(int percent) => switch (percent) {
    <= 10 => BatteryLevel.critical,
    <= 25 => BatteryLevel.low,
    <= 50 => BatteryLevel.medium,
    <= 75 => BatteryLevel.high,
    _ => BatteryLevel.full,
  };
}