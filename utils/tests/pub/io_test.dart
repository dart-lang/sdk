// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io_test;

import 'dart:io';

import '../../../pkg/pathos/lib/path.dart' as path;
import '../../../pkg/unittest/lib/unittest.dart';

import '../../pub/io.dart';
import '../../pub/utils.dart';
import 'test_pub.dart';

main() {
  initConfig();

  group('listDir', () {
    test('lists a simple directory non-recursively', () {
      expect(withTempDir((temp) {
        var future = defer(() {
          writeTextFile(path.join(temp, 'file1.txt'), '');
          writeTextFile(path.join(temp, 'file2.txt'), '');
          createDir(path.join(temp, 'subdir'));
          writeTextFile(path.join(temp, 'subdir', 'file3.txt'), '');
          return listDir(temp);
        });
        expect(future, completion(unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt'),
          path.join(temp, 'subdir')
        ])));
        return future;
      }), completes);
    });

    test('lists a simple directory recursively', () {
      expect(withTempDir((temp) {
        var future = defer(() {
          writeTextFile(path.join(temp, 'file1.txt'), '');
          writeTextFile(path.join(temp, 'file2.txt'), '');
          createDir(path.join(temp, 'subdir'));
          writeTextFile(path.join(temp, 'subdir', 'file3.txt'), '');
          return listDir(temp, recursive: true);
        });

        expect(future, completion(unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt'),
          path.join(temp, 'subdir'),
          path.join(temp, 'subdir', 'file3.txt'),
        ])));
        return future;
      }), completes);
    });

    test('ignores hidden files by default', () {
      expect(withTempDir((temp) {
        var future = defer(() {
          writeTextFile(path.join(temp, 'file1.txt'), '');
          writeTextFile(path.join(temp, 'file2.txt'), '');
          writeTextFile(path.join(temp, '.file3.txt'), '');
          createDir(path.join(temp, '.subdir'));
          writeTextFile(path.join(temp, '.subdir', 'file3.txt'), '');
          return listDir(temp, recursive: true);
        });
        expect(future, completion(unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt')
        ])));
        return future;
      }), completes);
    });

    test('includes hidden files when told to', () {
      expect(withTempDir((temp) {
        var future = defer(() {
          writeTextFile(path.join(temp, 'file1.txt'), '');
          writeTextFile(path.join(temp, 'file2.txt'), '');
          writeTextFile(path.join(temp, '.file3.txt'), '');
          createDir(path.join(temp, '.subdir'));
          writeTextFile(path.join(temp, '.subdir', 'file3.txt'), '');
          return listDir(temp, recursive: true, includeHiddenFiles: true);
        });
        expect(future, completion(unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt'),
          path.join(temp, '.file3.txt'),
          path.join(temp, '.subdir'),
          path.join(temp, '.subdir', 'file3.txt')
        ])));
        return future;
      }), completes);
    });

    test('returns the unresolved paths for symlinks', () {
      expect(withTempDir((temp) {
        var dirToList = path.join(temp, 'dir-to-list');
        var future = defer(() {
          createDir(path.join(temp, 'dir1'));
          writeTextFile(path.join(temp, 'dir1', 'file1.txt'), '');
          createDir(path.join(temp, 'dir2'));
          writeTextFile(path.join(temp, 'dir2', 'file2.txt'), '');
          createDir(dirToList);
          return createSymlink(path.join(temp, 'dir1'),
                               path.join(dirToList, 'linked-dir1'));
        }).then((_) {
          createDir(path.join(dirToList, 'subdir'));
          return createSymlink(
                  path.join(temp, 'dir2'),
                  path.join(dirToList, 'subdir', 'linked-dir2'));
        }).then((_) => listDir(dirToList, recursive: true));
        expect(future, completion(unorderedEquals([
          path.join(dirToList, 'linked-dir1'),
          path.join(dirToList, 'linked-dir1', 'file1.txt'),
          path.join(dirToList, 'subdir'),
          path.join(dirToList, 'subdir', 'linked-dir2'),
          path.join(dirToList, 'subdir', 'linked-dir2', 'file2.txt'),
        ])));
        return future;
      }), completes);
    });

    test('works with recursive symlinks', () {
      expect(withTempDir((temp) {
        var future = defer(() {
          writeTextFile(path.join(temp, 'file1.txt'), '');
          return createSymlink(temp, path.join(temp, 'linkdir'));
        }).then((_) => listDir(temp, recursive: true));
        expect(future, completion(unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'linkdir')
        ])));
        return future;
      }), completes);
    });
  });

  testExistencePredicate("entryExists", entryExists,
      forFile: true,
      forFileSymlink: true,
      forMultiLevelFileSymlink: true,
      forDirectory: true,
      forDirectorySymlink: true,
      forMultiLevelDirectorySymlink: true,
      forBrokenSymlink: true,
      forMultiLevelBrokenSymlink: true);

  testExistencePredicate("linkExists", linkExists,
      forFile: false,
      forFileSymlink: true,
      forMultiLevelFileSymlink: true,
      forDirectory: false,
      forDirectorySymlink: true,
      forMultiLevelDirectorySymlink: true,
      forBrokenSymlink: true,
      forMultiLevelBrokenSymlink: true);

  testExistencePredicate("fileExists", fileExists,
      forFile: true,
      forFileSymlink: true,
      forMultiLevelFileSymlink: true,
      forDirectory: false,
      forDirectorySymlink: false,
      forMultiLevelDirectorySymlink: false,
      forBrokenSymlink: false,
      forMultiLevelBrokenSymlink: false);

  testExistencePredicate("dirExists", dirExists,
      forFile: false,
      forFileSymlink: false,
      forMultiLevelFileSymlink: false,
      forDirectory: true,
      forDirectorySymlink: true,
      forMultiLevelDirectorySymlink: true,
      forBrokenSymlink: false,
      forMultiLevelBrokenSymlink: false);
}

void testExistencePredicate(String name, bool predicate(String path),
    {bool forFile,
     bool forFileSymlink,
     bool forMultiLevelFileSymlink,
     bool forDirectory,
     bool forDirectorySymlink,
     bool forMultiLevelDirectorySymlink,
     bool forBrokenSymlink,
     bool forMultiLevelBrokenSymlink}) {
  group(name, () {
    test('returns $forFile for a file', () {
      expect(withTempDir((temp) {
        var path = path.join(temp, "test.txt");
        writeTextFile(path, "contents");
        expect(predicate(path), equals(forFile));
      }), completes);
    });

    test('returns $forDirectory for a directory', () {
      expect(withTempDir((temp) {
        var path = path.join(temp, "dir");
        createDir(path);
        expect(predicate(path), equals(forDirectory));
      }), completes);
    });

    test('returns $forDirectorySymlink for a symlink to a directory', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlinkPath = path.join(temp, "linkdir");
        createDir(targetPath);
        return createSymlink(targetPath, symlinkPath).then((_) {
          expect(predicate(symlinkPath), equals(forDirectorySymlink));
        });
      }), completes);
    });

    test('returns $forMultiLevelDirectorySymlink for a multi-level symlink to '
        'a directory', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlink1Path = path.join(temp, "link1dir");
        var symlink2Path = path.join(temp, "link2dir");
        createDir(targetPath);
        return createSymlink(targetPath, symlink1Path)
            .then((_) => createSymlink(symlink1Path, symlink2Path))
            .then((_) {
          expect(predicate(symlink2Path),
              equals(forMultiLevelDirectorySymlink));
        });
      }), completes);
    });

    test('returns $forBrokenSymlink for a broken symlink', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlinkPath = path.join(temp, "linkdir");
        createDir(targetPath);
        return createSymlink(targetPath, symlinkPath).then((_) {
          deleteEntry(targetPath);
          expect(predicate(symlinkPath), equals(forBrokenSymlink));
        });
      }), completes);
    });

    test('returns $forMultiLevelBrokenSymlink for a multi-level broken symlink',
        () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlink1Path = path.join(temp, "link1dir");
        var symlink2Path = path.join(temp, "link2dir");
        createDir(targetPath);
        return createSymlink(targetPath, symlink1Path)
            .then((_) => createSymlink(symlink1Path, symlink2Path))
            .then((_) {
          deleteEntry(targetPath);
          expect(predicate(symlink2Path), equals(forMultiLevelBrokenSymlink));
        });
      }), completes);
    });

    // Windows doesn't support symlinking to files.
    if (Platform.operatingSystem != 'windows') {
      test('returns $forFileSymlink for a symlink to a file', () {
        expect(withTempDir((temp) {
          var targetPath = path.join(temp, "test.txt");
          var symlinkPath = path.join(temp, "link.txt");
          writeTextFile(targetPath, "contents");
          return createSymlink(targetPath, symlinkPath).then((_) {
            expect(predicate(symlinkPath), equals(forFileSymlink));
          });
        }), completes);
      });

      test('returns $forMultiLevelFileSymlink for a multi-level symlink to a '
          'file', () {
        expect(withTempDir((temp) {
          var targetPath = path.join(temp, "test.txt");
          var symlink1Path = path.join(temp, "link1.txt");
          var symlink2Path = path.join(temp, "link2.txt");
          writeTextFile(targetPath, "contents");
          return createSymlink(targetPath, symlink1Path)
              .then((_) => createSymlink(symlink1Path, symlink2Path))
              .then((_) {
            expect(predicate(symlink2Path), equals(forMultiLevelFileSymlink));
          });
        }), completes);
      });
    }
  });
}
