import 'package:flutter/material.dart';
import 'package:jezail_ui/core/enums/snackbar_type.dart';

class MySnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    Duration? duration,
    SnackBarAction? action,
  }) {
    Color backgroundColor;
    IconData icon;
    Duration defaultDuration;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle;
        defaultDuration = const Duration(seconds: 1);
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade600;
        icon = Icons.error;
        defaultDuration = const Duration(seconds: 2);
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.orange.shade600;
        icon = Icons.warning;
        defaultDuration = const Duration(seconds: 1);
        break;
      case SnackBarType.info:
        backgroundColor = Colors.blue.shade600;
        icon = Icons.info;
        defaultDuration = const Duration(seconds: 1);
        break;
    }

    final finalDuration = duration ?? defaultDuration;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: finalDuration,
        behavior: SnackBarBehavior.fixed, 
        action: action,
      ),
    );
  }

}

extension BuildContextSnackBars on BuildContext {
  void showSuccessSnackBar(
    String message, {
    Duration? duration, 
    SnackBarAction? action,
  }) {
    MySnackBar.show(this, message: message, type: SnackBarType.success, duration: duration, action: action);
  }

  void showErrorSnackBar(
    String message, {
    Duration? duration, 
    SnackBarAction? action,
  }) {
    MySnackBar.show(this, message: message, type: SnackBarType.error, duration: duration, action: action);
  }

  void showWarningSnackBar(
    String message, {
    Duration? duration, 
    SnackBarAction? action,
  }) {
    MySnackBar.show(this, message: message, type: SnackBarType.warning, duration: duration, action: action);
  }

  void showInfoSnackBar(
    String message, {
    Duration? duration, 
    SnackBarAction? action,
  }) {
    MySnackBar.show(this, message: message, type: SnackBarType.info, duration: duration, action: action);
  }

  Future<void> runWithFeedback({
    required Future<void> Function() action,
    required String successMessage,
    String? errorMessage,
    SnackBarType type = SnackBarType.success,
    SnackBarAction? actionButton,
  }) async {
    try {
      await action();
      if (!mounted) return;
      
      switch (type) {
        case SnackBarType.success:
          showSuccessSnackBar(successMessage, action: actionButton);
          break;
        case SnackBarType.info:
          showInfoSnackBar(successMessage, action: actionButton);
          break;
        case SnackBarType.warning:
          showWarningSnackBar(successMessage, action: actionButton);
          break;
        case SnackBarType.error:
          showErrorSnackBar(successMessage, action: actionButton);
          break;
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        '${errorMessage ?? "Operation failed"}: ${e.toString()}',
      );
    }
  }
}