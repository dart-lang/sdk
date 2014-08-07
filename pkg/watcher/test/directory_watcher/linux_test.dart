// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/src/directory_watcher/linux.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

void main() {
  initConfig();

  watcherFactory = (dir) => new LinuxDirectoryWatcher(dir);

  setUp(createSandbox);

  sharedTests();

  test('DirectoryWatcher creates a LinuxDirectoryWatcher on Linux', () {
    expect(new DirectoryWatcher('.'),
        new isInstanceOf<LinuxDirectoryWatcher>());
  });

  test('emits events for many nested files moved out then immediately back in',
      () {
    withPermutations((i, j, k) =>
        writeFile("dir/sub/sub-$i/sub-$j/file-$k.txt"));
    startWatcher(dir: "dir");

    renameDir("dir/sub", "sub");
    renameDir("sub", "dir/sub");

    allowEither(() {
      inAnyOrder(withPermutations((i, j, k) =>
          isRemoveEvent("dir/sub/sub-$i/sub-$j/file-$k.txt")));

      inAnyOrder(withPermutations((i, j, k) =>
          isAddEvent("dir/sub/sub-$i/sub-$j/file-$k.txt")));
    }, () {
      inAnyOrder(withPermutations((i, j, k) =>
          isModifyEvent("dir/sub/sub-$i/sub-$j/file-$k.txt")));
    });
  });
}
