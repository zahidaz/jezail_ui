import 'package:flutter/material.dart';
import 'package:jezail_ui/core/enums/snackbar_type.dart';

extension BuildContextExtensions on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showSnackbar(
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: _getColorForType(type),
      ),
    );
  }

  Color _getColorForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Colors.green;
      case SnackBarType.error:
        return Colors.red;
      case SnackBarType.warning:
        return Colors.orange;
      case SnackBarType.info:
        return Colors.blue;
    }
  }
}

extension NullableExtensions<T> on T? {
  T? ifNotNull(T Function(T) transform) {
    final value = this;
    if (value != null) {
      return transform(value);
    }
    return null;
  }
}