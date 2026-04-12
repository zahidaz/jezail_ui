
class ProcessInfo {
  const ProcessInfo({
    required this.pid,
    required this.name,
    this.ppid,
    this.user,
    this.vsz,
    this.stat,
    this.addr,
    this.wchan,
  });

  final int pid;
  final String name;
  final int? ppid;
  final String? user;
  final int? vsz;
  final String? stat;
  final String? addr;
  final String? wchan;

  String? get state => stat;

  factory ProcessInfo.fromJson(Map<String, dynamic> json) => ProcessInfo(
    pid: (json['pid'] as int?) ?? 0,
    name: (json['name'] as String?) ?? 'unknown',
    ppid: json['ppid'] as int?,
    user: json['user'] as String?,
    vsz: json['vsz'] as int?,
    stat: json['stat'] as String?,
    addr: json['addr'] as String?,
    wchan: json['wchan'] as String?,
  );
}

