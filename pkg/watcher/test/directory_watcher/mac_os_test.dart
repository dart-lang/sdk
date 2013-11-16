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

    // We sleep here because a narrow edge case caused by two interacting bugs
    // can produce events that aren't expected if we start the watcher too
    // soon after creating the files above. Here's what happens:
    //
    // * We create "dir/sub" and its contents above.
    //
    // * We initialize the watcher watching "dir".
    //
    // * Due to issue 14373, the watcher can receive native events describing
    //   the creation of "dir/sub" and its contents despite the fact that they
    //   occurred before the watcher was started.
    //
    // * Usually the above events will occur while the watcher is doing its
    //   initial scan of "dir/sub" and be ignored, but occasionally they will
    //   occur afterwards.
    //
    // * When processing the bogus CREATE events, the watcher has to assume that
    //   they could mean something other than CREATE (issue 14793). Thus it
    //   assumes that the files or directories in question could have changed
    //   and emits CHANGE events or additional REMOVE/CREATE pairs for them.
    schedule(() => new Future.delayed(new Duration(seconds: 2)));

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
