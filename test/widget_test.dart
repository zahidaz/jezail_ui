import 'package:flutter_test/flutter_test.dart';
import 'package:jezail_ui/models/files/file_info.dart';
import 'package:jezail_ui/models/files/file_explorer_view_state.dart';
import 'package:jezail_ui/models/files/file_operation_result.dart';
import 'package:jezail_ui/core/enums/file_enums.dart';

void main() {
  group('FileInfo.fromJson', () {
    test('parses standard file entry', () {
      final json = {
        'name': 'test.txt',
        'path': '/data/local/tmp/test.txt',
        'permissions': '-rw-r--r--',
        'owner': 'root',
        'group': 'root',
        'size': 1024,
        'lastModified': '2024-01-01 12:00',
        'isDirectory': false,
      };

      final file = FileInfo.fromJson(json);

      expect(file.displayName, 'test.txt');
      expect(file.path, '/data/local/tmp/test.txt');
      expect(file.permissions, '-rw-r--r--');
      expect(file.owner, 'root');
      expect(file.size, 1024);
      expect(file.isDirectory, false);
      expect(file.type, FileType.file);
    });

    test('parses directory entry', () {
      final json = {
        'name': 'mydir',
        'path': '/data/local/tmp/mydir',
        'permissions': 'drwxr-xr-x',
        'owner': 'shell',
        'group': 'shell',
        'size': 4096,
        'lastModified': '2024-01-01 12:00',
        'isDirectory': true,
      };

      final file = FileInfo.fromJson(json);

      expect(file.isDirectory, true);
      expect(file.type, FileType.directory);
    });

    test('parses symlink from name containing arrow', () {
      final json = {
        'name': 'link -> /target',
        'path': '/data/local/tmp/link',
        'permissions': 'lrwxrwxrwx',
        'owner': 'root',
        'group': 'root',
        'size': 0,
        'lastModified': '2024-01-01 12:00',
        'isDirectory': false,
      };

      final file = FileInfo.fromJson(json);

      expect(file.displayName, 'link');
      expect(file.symlinkTarget, '/target');
      expect(file.type, FileType.symlink);
    });

    test('handles missing fields gracefully', () {
      final json = <String, dynamic>{};

      final file = FileInfo.fromJson(json);

      expect(file.name, '');
      expect(file.path, '');
      expect(file.size, 0);
      expect(file.isDirectory, false);
    });

    test('parses size from string', () {
      final json = {
        'name': 'test',
        'path': '/test',
        'permissions': '-rw-r--r--',
        'owner': 'root',
        'group': 'root',
        'size': '2048',
        'lastModified': '',
        'isDirectory': false,
      };

      final file = FileInfo.fromJson(json);
      expect(file.size, 2048);
    });
  });

  group('FilePermissions', () {
    test('parses standard permission string', () {
      final perms = FilePermissions.fromString('-rwxr-xr--');

      expect(perms.ownerRead, true);
      expect(perms.ownerWrite, true);
      expect(perms.ownerExecute, true);
      expect(perms.groupRead, true);
      expect(perms.groupWrite, false);
      expect(perms.groupExecute, true);
      expect(perms.othersRead, true);
      expect(perms.othersWrite, false);
      expect(perms.othersExecute, false);
    });

    test('converts to octal', () {
      final perms = FilePermissions.fromString('-rwxr-xr--');
      expect(perms.toOctal(), '754');
    });

    test('handles short permission string', () {
      final perms = FilePermissions.fromString('');
      expect(perms.ownerRead, false);
      expect(perms.toOctal(), '000');
    });
  });

  group('FileExplorerViewState', () {
    test('default state', () {
      const state = FileExplorerViewState();

      expect(state.currentPath, '/data/local/tmp');
      expect(state.files, isEmpty);
      expect(state.isLoading, true);
      expect(state.selectedFiles, isEmpty);
    });

    test('copyWith preserves unmodified fields', () {
      const state = FileExplorerViewState();
      final newState = state.copyWith(currentPath: '/sdcard');

      expect(newState.currentPath, '/sdcard');
      expect(newState.sortField, state.sortField);
      expect(newState.sortAscending, state.sortAscending);
    });

    test('getParentPath returns parent', () {
      final state = const FileExplorerViewState().copyWith(
        currentPath: '/data/local/tmp/foo',
      );

      expect(state.getParentPath(), '/data/local/tmp');
    });

    test('getChildPath appends child name', () {
      const state = FileExplorerViewState();

      expect(state.getChildPath('foo'), '/data/local/tmp/foo');
    });

    test('canNavigateUp from root', () {
      final state = const FileExplorerViewState().copyWith(currentPath: '/');
      expect(state.canNavigateUp, false);
    });
  });

  group('FileOperationResult', () {
    test('Success contains data', () {
      const result = Success(42);
      expect(result.dataOrNull, 42);
      expect(result.isLoading, false);
      expect(result.isError, false);
    });

    test('Loading has no data', () {
      const result = Loading<int>();
      expect(result.dataOrNull, null);
      expect(result.isLoading, true);
    });

    test('Error contains message', () {
      final result = Error<int>('fail', Exception('test'));
      expect(result.errorOrNull, 'fail');
      expect(result.isError, true);
      expect(result.dataOrNull, null);
    });
  });
}
