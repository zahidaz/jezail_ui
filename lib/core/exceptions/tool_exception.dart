class ToolOperationException implements Exception {
  final String message;
  final String? tool;
  
  const ToolOperationException(this.message, [this.tool]);
  
  @override
  String toString() => 'ToolOperationException: $message${tool != null ? ' (Tool: $tool)' : ''}';
}