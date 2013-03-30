// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io_test;

import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:unittest/unittest.dart';

import '../../pub/io.dart';
import '../../pub/utils.dart';
import 'test_pub.dart';

main() {
  initConfig();

  group('listDir', () {
    test('lists a simple directory non-recursively', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        writeTextFile(path.join(temp, 'file2.txt'), '');
        createDir(path.join(temp, 'subdir'));
        writeTextFile(path.join(temp, 'subdir', 'file3.txt'), '');

        expect(listDir(temp), unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt'),
          path.join(temp, 'subdir')
        ]));
      }), completes);
    });

    test('lists a simple directory recursively', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        writeTextFile(path.join(temp, 'file2.txt'), '');
        createDir(path.join(temp, 'subdir'));
        writeTextFile(path.join(temp, 'subdir', 'file3.txt'), '');

        expect(listDir(temp, recursive: true), unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt'),
          path.join(temp, 'subdir'),
          path.join(temp, 'subdir', 'file3.txt'),
        ]));
      }), completes);
    });

    test('ignores hidden files by default', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        writeTextFile(path.join(temp, 'file2.txt'), '');
        writeTextFile(path.join(temp, '.file3.txt'), '');
        createDir(path.join(temp, '.subdir'));
        writeTextFile(path.join(temp, '.subdir', 'file3.txt'), '');

        expect(listDir(temp, recursive: true), unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt')
        ]));
      }), completes);
    });

    test('includes hidden files when told to', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        writeTextFile(path.join(temp, 'file2.txt'), '');
        writeTextFile(path.join(temp, '.file3.txt'), '');
        createDir(path.join(temp, '.subdir'));
        writeTextFile(path.join(temp, '.subdir', 'file3.txt'), '');

        expect(listDir(temp, recursive: true, includeHidden: true),
            unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'file2.txt'),
          path.join(temp, '.file3.txt'),
          path.join(temp, '.subdir'),
          path.join(temp, '.subdir', 'file3.txt')
        ]));
      }), completes);
    });

    test('returns the unresolved paths for symlinks', () {
      expect(withTempDir((temp) {
        var dirToList = path.join(temp, 'dir-to-list');
        createDir(path.join(temp, 'dir1'));
        writeTextFile(path.join(temp, 'dir1', 'file1.txt'), '');
        createDir(path.join(temp, 'dir2'));
        writeTextFile(path.join(temp, 'dir2', 'file2.txt'), '');
        createDir(dirToList);
        createSymlink(
            path.join(temp, 'dir1'),
            path.join(dirToList, 'linked-dir1'));
        createDir(path.join(dirToList, 'subdir'));
        createSymlink(
            path.join(temp, 'dir2'),
            path.join(dirToList, 'subdir', 'linked-dir2'));

        expect(listDir(dirToList, recursive: true), unorderedEquals([
          path.join(dirToList, 'linked-dir1'),
          path.join(dirToList, 'linked-dir1', 'file1.txt'),
          path.join(dirToList, 'subdir'),
          path.join(dirToList, 'subdir', 'linked-dir2'),
          path.join(dirToList, 'subdir', 'linked-dir2', 'file2.txt'),
        ]));
      }), completes);
    });

    test('works with recursive symlinks', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        createSymlink(temp, path.join(temp, 'linkdir'));

        expect(listDir(temp, recursive: true), unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'linkdir')
        ]));
      }), completes);
    });

    test('treats a broken symlink as a file', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        createDir(path.join(temp, 'dir'));
        createSymlink(path.join(temp, 'dir'), path.join(temp, 'linkdir'));
        deleteEntry(path.join(temp, 'dir'));

        expect(listDir(temp, recursive: true), unorderedEquals([
          path.join(temp, 'file1.txt'),
          path.join(temp, 'linkdir')
        ]));
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
        var file = path.join(temp, "test.txt");
        writeTextFile(file, "contents");
        expect(predicate(file), equals(forFile));
      }), completes);
    });

    test('returns $forDirectory for a directory', () {
      expect(withTempDir((temp) {
        var file = path.join(temp, "dir");
        createDir(file);
        expect(predicate(file), equals(forDirectory));
      }), completes);
    });

    test('returns $forDirectorySymlink for a symlink to a directory', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlinkPath = path.join(temp, "linkdir");
        createDir(targetPath);
        createSymlink(targetPath, symlinkPath);
        expect(predicate(symlinkPath), equals(forDirectorySymlink));
      }), completes);
    });

    test('returns $forMultiLevelDirectorySymlink for a multi-level symlink to '
        'a directory', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlink1Path = path.join(temp, "link1dir");
        var symlink2Path = path.join(temp, "link2dir");
        createDir(targetPath);
        createSymlink(targetPath, symlink1Path);
        createSymlink(symlink1Path, symlink2Path);
        expect(predicate(symlink2Path),
              equals(forMultiLevelDirectorySymlink));
      }), completes);
    });

    test('returns $forBrokenSymlink for a broken symlink', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlinkPath = path.join(temp, "linkdir");
        createDir(targetPath);
        createSymlink(targetPath, symlinkPath);
        deleteEntry(targetPath);
        expect(predicate(symlinkPath), equals(forBrokenSymlink));
      }), completes);
    });

    test('returns $forMultiLevelBrokenSymlink for a multi-level broken symlink',
        () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlink1Path = path.join(temp, "link1dir");
        var symlink2Path = path.join(temp, "link2dir");
        createDir(targetPath);
        createSymlink(targetPath, symlink1Path);
        createSymlink(symlink1Path, symlink2Path);
        deleteEntry(targetPath);
        expect(predicate(symlink2Path), equals(forMultiLevelBrokenSymlink));
      }), completes);
    });

    // Windows doesn't support symlinking to files.
    if (Platform.operatingSystem != 'windows') {
      test('returns $forFileSymlink for a symlink to a file', () {
        expect(withTempDir((temp) {
          var targetPath = path.join(temp, "test.txt");
          var symlinkPath = path.join(temp, "link.txt");
          writeTextFile(targetPath, "contents");
          createSymlink(targetPath, symlinkPath);
          expect(predicate(symlinkPath), equals(forFileSymlink));
        }), completes);
      });

      test('returns $forMultiLevelFileSymlink for a multi-level symlink to a '
          'file', () {
        expect(withTempDir((temp) {
          var targetPath = path.join(temp, "test.txt");
          var symlink1Path = path.join(temp, "link1.txt");
          var symlink2Path = path.join(temp, "link2.txt");
          writeTextFile(targetPath, "contents");
          createSymlink(targetPath, symlink1Path);
          createSymlink(symlink1Path, symlink2Path);
          expect(predicate(symlink2Path), equals(forMultiLevelFileSymlink));
        }), completes);
      });
    }
  });
}
