class FridaInfo {
  final String currentVersion;
  final String latestVersion;
  final bool needsUpdate;
  final String installPath;

  const FridaInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.needsUpdate,
    required this.installPath,
  });
}