import 'package:flutter/material.dart';
import 'package:jezail_ui/core/enums/snackbar_type.dart';
import 'package:jezail_ui/presentation/widgets/custom_snackbar.dart';

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