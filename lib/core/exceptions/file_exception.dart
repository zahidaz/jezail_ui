class FileOperationException implements Exception {
  final String message;
  final String? path;
  
  const FileOperationException(this.message, [this.path]);
  
  @override
  String toString() => 'FileOperationException: $message${path != null ? ' (Path: $path)' : ''}';
}