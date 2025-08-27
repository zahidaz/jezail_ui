import 'package:flutter/material.dart';

extension BuildContextSnackBars on BuildContext {
  void showSuccessSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle,
      duration: duration ?? const Duration(seconds: 1),
      action: action,
    );
  }

  void showErrorSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error,
      duration: duration ?? const Duration(seconds: 2),
      action: action,
    );
  }

  void showWarningSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      backgroundColor: Colors.orange.shade600,
      icon: Icons.warning,
      duration: duration ?? const Duration(seconds: 1),
      action: action,
    );
  }

  void showInfoSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      message,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info,
      duration: duration ?? const Duration(seconds: 1),
      action: action,
    );
  }

  void showSnackBar(String message) {
    _showSnackBar(
      message,
      backgroundColor: Theme.of(this).colorScheme.inverseSurface,
      duration: const Duration(seconds: 1),
    );
  }

  void _showSnackBar(
    String message, {
    required Color backgroundColor,
    IconData? icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
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
        duration: duration,
        behavior: SnackBarBehavior.fixed,
        action: action,
      ),
    );
  }

  Future<void> runWithFeedback({
    required Future<void> Function() action,
    required String successMessage,
    String? errorMessage,
    SnackBarAction? actionButton,
  }) async {
    try {
      await action();
      if (!mounted) return;
      showSuccessSnackBar(successMessage, action: actionButton);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        '${errorMessage ?? "Operation failed"}: ${e.toString()}',
      );
    }
  }
}