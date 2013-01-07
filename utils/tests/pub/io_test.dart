// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library io_test;

import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/io.dart';

main() {
  group('listDir', () {
    test('lists a simple directory non-recursively', () {
      expect(withTempDir((path) {
        var future = writeTextFile(join(path, 'file1.txt'), '')
            .then((_) => writeTextFile(join(path, 'file2.txt'), ''))
            .then((_) => createDir(join(path, 'subdir')))
            .then((_) => writeTextFile(join(path, 'subdir', 'file3.txt'), ''))
            .then((_) => listDir(path));
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
        var future = writeTextFile(join(path, 'file1.txt'), '')
            .then((_) => writeTextFile(join(path, 'file2.txt'), ''))
            .then((_) => createDir(join(path, 'subdir')))
            .then((_) => writeTextFile(join(path, 'subdir', 'file3.txt'), ''))
            .then((_) => listDir(path, recursive: true));
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'file2.txt'),
          join(path, 'subdir'),
          join(path, 'subdir/file3.txt'),
        ])));
        return future;
      }), completes);
    });

    test('ignores hidden files by default', () {
      expect(withTempDir((path) {
        var future = writeTextFile(join(path, 'file1.txt'), '')
            .then((_) => writeTextFile(join(path, 'file2.txt'), ''))
            .then((_) => writeTextFile(join(path, '.file3.txt'), ''))
            .then((_) => createDir(join(path, '.subdir')))
            .then((_) => writeTextFile(join(path, '.subdir', 'file3.txt'), ''))
            .then((_) => listDir(path, recursive: true));
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'file2.txt')
        ])));
        return future;
      }), completes);
    });

    test('includes hidden files when told to', () {
      expect(withTempDir((path) {
        var future = writeTextFile(join(path, 'file1.txt'), '')
            .then((_) => writeTextFile(join(path, 'file2.txt'), ''))
            .then((_) => writeTextFile(join(path, '.file3.txt'), ''))
            .then((_) => createDir(join(path, '.subdir')))
            .then((_) => writeTextFile(join(path, '.subdir', 'file3.txt'), ''))
            .then((_) {
              return listDir(path, recursive: true, includeHiddenFiles: true);
            });
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'file2.txt'),
          join(path, '.file3.txt'),
          join(path, '.subdir'),
          join(path, '.subdir/file3.txt')
        ])));
        return future;
      }), completes);
    });

    test('returns the unresolved paths for symlinks', () {
      expect(withTempDir((path) {
        var dirToList = join(path, 'dir-to-list');
        var future = writeTextFile(join(path, 'file1.txt'), '')
            .then((_) => writeTextFile(join(path, 'file2.txt'), ''))
            .then((_) => createDir(dirToList))
            .then((_) {
              return createSymlink(
                  join(path, 'file1.txt'),
                  join(dirToList, 'link1'));
            }).then((_) => createDir(join(dirToList, 'subdir')))
            .then((_) {
              return createSymlink(
                  join(path, 'file2.txt'),
                  join(dirToList, 'subdir', 'link2'));
            }).then((_) => listDir(dirToList, recursive: true));
        expect(future, completion(unorderedEquals([
          join(dirToList, 'link1'),
          join(dirToList, 'subdir'),
          join(dirToList, 'subdir/link2'),
        ])));
        return future;
      }), completes);
    });

    test('works with recursive symlinks', () {
      expect(withTempDir((path) {
        var future = writeTextFile(join(path, 'file1.txt'), '')
            .then((_) => createSymlink(path, join(path, 'linkdir')))
            .then((_) => listDir(path, recursive: true));
        expect(future, completion(unorderedEquals([
          join(path, 'file1.txt'),
          join(path, 'linkdir')
        ])));
        return future;
      }), completes);
    });
  });
}
