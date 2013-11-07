// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/src/directory_watcher/linux.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

main() {
  initConfig();

  watcherFactory = (dir) => new LinuxDirectoryWatcher(dir);

  setUp(() {
    // Increase the timeout because closing a [Directory.watch] stream blocks
    // the main isolate for a very long time on Goobuntu, as of kernel
    // 3.2.5-gg1336 (see issue 14606).
    currentSchedule.timeout *= 3;

    createSandbox();
  });

  sharedTests();

  test('DirectoryWatcher creates a LinuxDirectoryWatcher on Linux', () {
    expect(new DirectoryWatcher('.'),
        new isInstanceOf<LinuxDirectoryWatcher>());
  });

  test('notifies even if the file contents are unchanged', () {
    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "before");
    startWatcher();
    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "after");
    expectModifyEvent("a.txt");
    expectModifyEvent("b.txt");
  });

  test('emits events for many nested files moved out then immediately back in',
      () {
    withPermutations((i, j, k) =>
        writeFile("dir/sub/sub-$i/sub-$j/file-$k.txt"));
    startWatcher(dir: "dir");

    renameDir("dir/sub", "sub");
    renameDir("sub", "dir/sub");

    inAnyOrder(() {
      withPermutations((i, j, k) =>
          expectRemoveEvent("dir/sub/sub-$i/sub-$j/file-$k.txt"));
    });

    inAnyOrder(() {
      withPermutations((i, j, k) =>
          expectAddEvent("dir/sub/sub-$i/sub-$j/file-$k.txt"));
    });
  });
}
