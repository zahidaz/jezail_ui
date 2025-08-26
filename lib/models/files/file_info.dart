import '../../core/enums/file_enums.dart';

class FileInfo {
  final String name;
  final String path;
  final String displayName;
  final String? symlinkTarget;
  final String permissions;
  final String owner;
  final String group;
  final int size;
  final String lastModified;
  final bool isDirectory;
  final FileType type;
  final String? mimeType;

  const FileInfo({
    required this.name,
    required this.path,
    required this.displayName,
    this.symlinkTarget,
    required this.permissions,
    required this.owner,
    required this.group,
    required this.size,
    required this.lastModified,
    required this.isDirectory,
    required this.type,
    this.mimeType,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final permissions = json['permissions']?.toString() ?? '';
    final path = json['path']?.toString() ?? '';
    String displayName = rawName;
    String? symlinkTarget;

    if (json.containsKey('path') && json.containsKey('isFile')) {
      if (json['isSymbolicLink'] == true && rawName.startsWith('-> ')) {
        final parts = rawName.split('-> ');
        if (parts.length == 2) {
          symlinkTarget = parts[1].trim();
          final lastModifiedStr = json['lastModified']?.toString() ?? '';
          final modParts = lastModifiedStr.split(' ');
          if (modParts.length > 2) {
            displayName = modParts.sublist(2).join(' ');
          } else {
            displayName = symlinkTarget.split('/').last;
          }
        }
      } else {
        displayName = rawName;
      }
    } else {
      if (rawName.contains('-> ')) {
        final parts = rawName.split('-> ');
        if (parts.length == 2) {
          displayName = parts[0].trim();
          symlinkTarget = parts[1].trim();
        }
      }

      if (displayName == rawName && displayName.isEmpty) {
        final lastModified = json['lastModified']?.toString() ?? '';
        final parts = lastModified.split(' ');
        if (parts.length > 2) {
          displayName = parts.sublist(2).join(' ');
        }
      }
    }
    String lastModified = '';
    if (json['lastModified'] is int) {
      lastModified = json['lastModifiedFormatted']?.toString() ?? '';
    } else {
      lastModified = json['lastModified']?.toString() ?? '';
    }

    return FileInfo(
      name: rawName,
      path: path,
      displayName: displayName,
      symlinkTarget: symlinkTarget,
      permissions: permissions,
      owner: json['owner']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      size: _parseInt(json['size']),
      lastModified: lastModified,
      isDirectory: json['isDirectory'] as bool? ?? false,
      type: _parseFileType(permissions, json['isDirectory'] as bool? ?? false),
      mimeType: json['mimeType']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static FileType _parseFileType(String permissions, bool isDirectory) {
    if (isDirectory) return FileType.directory;

    if (permissions.isNotEmpty) {
      switch (permissions[0]) {
        case 'd':
          return FileType.directory;
        case 'l':
          return FileType.symlink;
        case 's':
          return FileType.socket;
        case 'p':
          return FileType.pipe;
        case 'b':
          return FileType.block;
        case 'c':
          return FileType.character;
        case '-':
        default:
          return FileType.file;
      }
    }

    return FileType.file;
  }

  bool get isSymlink => type == FileType.symlink;
  bool get isFile => type == FileType.file;
  bool get isRegularFile => type == FileType.file && !isSymlink;

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  FilePermissions get parsedPermissions =>
      FilePermissions.fromString(permissions);

  bool get isLikelyTextFile {
    if (isDirectory) return false;
    if (mimeType == null) return true; // Unknown MIME type, let user decide
    
    return mimeType!.startsWith('text/');
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'displayName': displayName,
    'symlinkTarget': symlinkTarget,
    'permissions': permissions,
    'owner': owner,
    'group': group,
    'size': size,
    'lastModified': lastModified,
    'isDirectory': isDirectory,
    'type': type.name,
    'mimeType': mimeType,
  };
}


class FilePermissions {
  final bool ownerRead;
  final bool ownerWrite;
  final bool ownerExecute;
  final bool groupRead;
  final bool groupWrite;
  final bool groupExecute;
  final bool othersRead;
  final bool othersWrite;
  final bool othersExecute;

  const FilePermissions({
    required this.ownerRead,
    required this.ownerWrite,
    required this.ownerExecute,
    required this.groupRead,
    required this.groupWrite,
    required this.groupExecute,
    required this.othersRead,
    required this.othersWrite,
    required this.othersExecute,
  });

  factory FilePermissions.fromString(String permissions) {
    if (permissions.length < 10) {
      return const FilePermissions(
        ownerRead: false,
        ownerWrite: false,
        ownerExecute: false,
        groupRead: false,
        groupWrite: false,
        groupExecute: false,
        othersRead: false,
        othersWrite: false,
        othersExecute: false,
      );
    }

    return FilePermissions(
      ownerRead: permissions[1] == 'r',
      ownerWrite: permissions[2] == 'w',
      ownerExecute: permissions[3] == 'x' || permissions[3] == 's',
      groupRead: permissions[4] == 'r',
      groupWrite: permissions[5] == 'w',
      groupExecute: permissions[6] == 'x' || permissions[6] == 's',
      othersRead: permissions[7] == 'r',
      othersWrite: permissions[8] == 'w',
      othersExecute: permissions[9] == 'x' || permissions[9] == 't',
    );
  }

  String toOctal() {
    int owner =
        (ownerRead ? 4 : 0) + (ownerWrite ? 2 : 0) + (ownerExecute ? 1 : 0);
    int group =
        (groupRead ? 4 : 0) + (groupWrite ? 2 : 0) + (groupExecute ? 1 : 0);
    int others =
        (othersRead ? 4 : 0) + (othersWrite ? 2 : 0) + (othersExecute ? 1 : 0);
    return '$owner$group$others';
  }

  String get humanReadable {
    return '${ownerRead ? 'r' : '-'}${ownerWrite ? 'w' : '-'}${ownerExecute ? 'x' : '-'}'
        '${groupRead ? 'r' : '-'}${groupWrite ? 'w' : '-'}${groupExecute ? 'x' : '-'}'
        '${othersRead ? 'r' : '-'}${othersWrite ? 'w' : '-'}${othersExecute ? 'x' : '-'}';
  }
}

