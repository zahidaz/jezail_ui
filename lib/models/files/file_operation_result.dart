sealed class FileOperationResult<T> {
  const FileOperationResult();
}

final class Success<T> extends FileOperationResult<T> {
  const Success(this.data);
  final T data;
}

final class Loading<T> extends FileOperationResult<T> {
  const Loading();
}

final class Error<T> extends FileOperationResult<T> {
  const Error(this.message, [this.exception]);
  final String message;
  final Exception? exception;
}

extension FileOperationResultExtensions<T> on FileOperationResult<T> {
  bool get isLoading => switch (this) {
    Loading<T>() => true,
    _ => false,
  };

  bool get isSuccess => switch (this) {
    Success<T>() => true,
    _ => false,
  };

  bool get isError => switch (this) {
    Error<T>() => true,
    _ => false,
  };

  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    _ => null,
  };

  String? get errorOrNull => switch (this) {
    Error<T>(message: final message) => message,
    _ => null,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function() loading,
    required R Function(String message, Exception? exception) error,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Loading<T>() => loading(),
      Error<T>(message: final message, exception: final exception) => error(message, exception),
    };
  }
}