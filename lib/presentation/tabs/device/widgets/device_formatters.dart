import 'package:flutter/material.dart';

class CardConfig {
  final String title;
  final IconData icon;
  final String dataKey;
  final Map<String, dynamic> Function(Map<String, dynamic>) processor;

  CardConfig(this.title, this.icon, this.dataKey, this.processor);
}

String formatBytes(dynamic bytes) {
  if (bytes == null || bytes == 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = (bytes as num).toDouble();
  var suffixIndex = 0;
  while (size >= 1024 && suffixIndex < suffixes.length - 1) {
    size /= 1024;
    suffixIndex++;
  }
  return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[suffixIndex]}';
}

String getBatteryStatus(int? status) => switch (status) {
  2 => 'Charging',
  3 => 'Discharging',
  4 => 'Not charging',
  5 => 'Full',
  _ => 'Unknown',
};

String getBatteryHealth(int? health) => switch (health) {
  2 => 'Good',
  3 => 'Overheat',
  4 => 'Dead',
  5 => 'Over voltage',
  6 => 'Failure',
  7 => 'Cold',
  _ => 'Unknown',
};

String getBatteryPluggedType(int? pluggedTypes) => switch (pluggedTypes) {
  0 => 'None',
  1 => 'AC',
  2 => 'USB',
  4 => 'Wireless',
  _ => 'Unknown',
};
