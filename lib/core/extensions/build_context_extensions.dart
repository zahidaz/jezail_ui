import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
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