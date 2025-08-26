
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
  double? get cpuUsage => null;

  factory ProcessInfo.fromJson(Map<String, dynamic> json) => ProcessInfo(
    pid: json['pid'] ?? 0,
    name: json['name'] ?? '',
    ppid: json['ppid'],
    user: json['user'],
    vsz: json['vsz'],
    stat: json['stat'],
    addr: json['addr'],
    wchan: json['wchan'],
  );
}

