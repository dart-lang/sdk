// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/src/directory_watcher/mac_os.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

main() {
  initConfig();
  MacOSDirectoryWatcher.logDebugInfo = true;

  watcherFactory = (dir) => new MacOSDirectoryWatcher(dir);

  setUp(createSandbox);

  sharedTests();

  test('DirectoryWatcher creates a MacOSDirectoryWatcher on Mac OS', () {
    expect(new DirectoryWatcher('.'),
        new isInstanceOf<MacOSDirectoryWatcher>());
  });

  test('does not notify about the watched directory being deleted and '
      'recreated immediately before watching', () {
    createDir("dir");
    writeFile("dir/old.txt");
    deleteDir("dir");
    createDir("dir");

    startWatcher(dir: "dir");
    writeFile("dir/newer.txt");
    expectAddEvent("dir/newer.txt");
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
