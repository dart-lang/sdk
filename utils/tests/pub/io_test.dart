// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io_test;

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
}
