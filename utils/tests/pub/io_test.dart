// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io_test;

import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/io.dart';
import '../../pub/utils.dart';
import 'test_pub.dart';

main() {
  initConfig();

  group('listDir', () {
    test('lists a simple directory non-recursively', () {
      expect(withTempDir((path) {
        var future = defer(() {
          writeTextFile(join(path, 'file1.txt'), '');
          writeTextFile(join(path, 'file2.txt'), '');
          createDir(join(path, 'subdir'));
          writeTextFile(join(path, 'subdir', 'file3.txt'), '');
          return listDir(path);
        });
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'file2.txt'),
          join(path, 'subdir')
        ])));
        return future;
      }), completes);
    });

    test('lists a simple directory recursively', () {
      expect(withTempDir((path) {
        var future = defer(() {
          writeTextFile(join(path, 'file1.txt'), '');
          writeTextFile(join(path, 'file2.txt'), '');
          createDir(join(path, 'subdir'));
          writeTextFile(join(path, 'subdir', 'file3.txt'), '');
          return listDir(path, recursive: true);
        });

        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'file2.txt'),
          join(path, 'subdir'),
          join(path, 'subdir', 'file3.txt'),
        ])));
        return future;
      }), completes);
    });

    test('ignores hidden files by default', () {
      expect(withTempDir((path) {
        var future = defer(() {
          writeTextFile(join(path, 'file1.txt'), '');
          writeTextFile(join(path, 'file2.txt'), '');
          writeTextFile(join(path, '.file3.txt'), '');
          createDir(join(path, '.subdir'));
          writeTextFile(join(path, '.subdir', 'file3.txt'), '');
          return listDir(path, recursive: true);
        });
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'file2.txt')
        ])));
        return future;
      }), completes);
    });

    test('includes hidden files when told to', () {
      expect(withTempDir((path) {
        var future = defer(() {
          writeTextFile(join(path, 'file1.txt'), '');
          writeTextFile(join(path, 'file2.txt'), '');
          writeTextFile(join(path, '.file3.txt'), '');
          createDir(join(path, '.subdir'));
          writeTextFile(join(path, '.subdir', 'file3.txt'), '');
          return listDir(path, recursive: true, includeHiddenFiles: true);
        });
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'file2.txt'),
          join(path, '.file3.txt'),
          join(path, '.subdir'),
          join(path, '.subdir', 'file3.txt')
        ])));
        return future;
      }), completes);
    });

    test('returns the unresolved paths for symlinks', () {
      expect(withTempDir((path) {
        var dirToList = join(path, 'dir-to-list');
        var future = defer(() {
          createDir(join(path, 'dir1'));
          writeTextFile(join(path, 'dir1', 'file1.txt'), '');
          createDir(join(path, 'dir2'));
          writeTextFile(join(path, 'dir2', 'file2.txt'), '');
          createDir(dirToList);
          return createSymlink(join(path, 'dir1'),
                               join(dirToList, 'linked-dir1'));
        }).then((_) {
          createDir(join(dirToList, 'subdir'));
          return createSymlink(
                  join(path, 'dir2'),
                  join(dirToList, 'subdir', 'linked-dir2'));
        }).then((_) => listDir(dirToList, recursive: true));
        expect(future, completion(unorderedEquals([
          join(dirToList, 'linked-dir1'),
          join(dirToList, 'linked-dir1', 'file1.txt'),
          join(dirToList, 'subdir'),
          join(dirToList, 'subdir', 'linked-dir2'),
          join(dirToList, 'subdir', 'linked-dir2', 'file2.txt'),
        ])));
        return future;
      }), completes);
    });

    test('works with recursive symlinks', () {
      expect(withTempDir((path) {
        var future = defer(() {
          writeTextFile(join(path, 'file1.txt'), '');
          return createSymlink(path, join(path, 'linkdir'));
        }).then((_) => listDir(path, recursive: true));
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'linkdir')
        ])));
        return future;
      }), completes);
    });
  });
}
