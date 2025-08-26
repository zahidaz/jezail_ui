class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  const ApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}