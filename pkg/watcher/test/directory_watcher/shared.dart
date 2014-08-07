// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/src/utils.dart';

import '../utils.dart';

void sharedTests() {
  test('does not notify for files that already exist when started', () {
    // Make some pre-existing files.
    writeFile("a.txt");
    writeFile("b.txt");

    startWatcher();

    // Change one after the watcher is running.
    writeFile("b.txt", contents: "modified");

    // We should get a modify event for the changed file, but no add events
    // for them before this.
    expectModifyEvent("b.txt");
  });

  test('notifies when a file is added', () {
    startWatcher();
    writeFile("file.txt");
    expectAddEvent("file.txt");
  });

  test('notifies when a file is modified', () {
    writeFile("file.txt");
    startWatcher();
    writeFile("file.txt", contents: "modified");
    expectModifyEvent("file.txt");
  });

  test('notifies when a file is removed', () {
    writeFile("file.txt");
    startWatcher();
    deleteFile("file.txt");
    expectRemoveEvent("file.txt");
  });

  test('notifies when a file is modified multiple times', () {
    writeFile("file.txt");
    startWatcher();
    writeFile("file.txt", contents: "modified");
    expectModifyEvent("file.txt");
    writeFile("file.txt", contents: "modified again");
    expectModifyEvent("file.txt");
  });

  test('notifies even if the file contents are unchanged', () {
    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "before");
    startWatcher();

    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "after");
    inAnyOrder([
      isModifyEvent("a.txt"),
      isModifyEvent("b.txt")
    ]);
  });

  test('when the watched directory is deleted, removes all files', () {
    writeFile("dir/a.txt");
    writeFile("dir/b.txt");

    startWatcher(dir: "dir");

    deleteDir("dir");
    inAnyOrder([
      isRemoveEvent("dir/a.txt"),
      isRemoveEvent("dir/b.txt")
    ]);
  });

  test('when the watched directory is moved, removes all files', () {
    writeFile("dir/a.txt");
    writeFile("dir/b.txt");

    startWatcher(dir: "dir");

    renameDir("dir", "moved_dir");
    createDir("dir");
    inAnyOrder([
      isRemoveEvent("dir/a.txt"),
      isRemoveEvent("dir/b.txt")
    ]);
  });

  group("moves", () {
    test('notifies when a file is moved within the watched directory', () {
      writeFile("old.txt");
      startWatcher();
      renameFile("old.txt", "new.txt");

      inAnyOrder([
        isAddEvent("new.txt"),
        isRemoveEvent("old.txt")
      ]);
    });

    test('notifies when a file is moved from outside the watched directory',
        () {
      writeFile("old.txt");
      createDir("dir");
      startWatcher(dir: "dir");

      renameFile("old.txt", "dir/new.txt");
      expectAddEvent("dir/new.txt");
    });

    test('notifies when a file is moved outside the watched directory', () {
      writeFile("dir/old.txt");
      startWatcher(dir: "dir");

      renameFile("dir/old.txt", "new.txt");
      expectRemoveEvent("dir/old.txt");
    });
  });

  // Most of the time, when multiple filesystem actions happen in sequence,
  // they'll be batched together and the watcher will see them all at once.
  // These tests verify that the watcher normalizes and combine these events
  // properly. However, very occasionally the events will be reported in
  // separate batches, and the watcher will report them as though they occurred
  // far apart in time, so each of these tests has a "backup case" to allow for
  // that as well.
  group("clustered changes", () {
    test("doesn't notify when a file is created and then immediately removed",
        () {
      startWatcher();
      writeFile("file.txt");
      deleteFile("file.txt");

      // Backup case.
      startClosingEventStream();
      allowEvents(() {
        expectAddEvent("file.txt");
        expectRemoveEvent("file.txt");
      });
    });

    test("reports a modification when a file is deleted and then immediately "
        "recreated", () {
      writeFile("file.txt");
      startWatcher();

      deleteFile("file.txt");
      writeFile("file.txt", contents: "re-created");

      allowEither(() {
        expectModifyEvent("file.txt");
      }, () {
        // Backup case.
        expectRemoveEvent("file.txt");
        expectAddEvent("file.txt");
      });
    });

    test("reports a modification when a file is moved and then immediately "
        "recreated", () {
      writeFile("old.txt");
      startWatcher();

      renameFile("old.txt", "new.txt");
      writeFile("old.txt", contents: "re-created");

      allowEither(() {
        inAnyOrder([
          isModifyEvent("old.txt"),
          isAddEvent("new.txt")
        ]);
      }, () {
        // Backup case.
        expectRemoveEvent("old.txt");
        expectAddEvent("new.txt");
        expectAddEvent("old.txt");
      });
    });

    test("reports a removal when a file is modified and then immediately "
        "removed", () {
      writeFile("file.txt");
      startWatcher();

      writeFile("file.txt", contents: "modified");
      deleteFile("file.txt");

      // Backup case.
      allowModifyEvent("file.txt");

      expectRemoveEvent("file.txt");
    });

    test("reports an add when a file is added and then immediately modified",
        () {
      startWatcher();

      writeFile("file.txt");
      writeFile("file.txt", contents: "modified");

      expectAddEvent("file.txt");

      // Backup case.
      startClosingEventStream();
      allowModifyEvent("file.txt");
    });
  });

  group("subdirectories", () {
    test('watches files in subdirectories', () {
      startWatcher();
      writeFile("a/b/c/d/file.txt");
      expectAddEvent("a/b/c/d/file.txt");
    });

    test('notifies when a subdirectory is moved within the watched directory '
        'and then its contents are modified', () {
      writeFile("old/file.txt");
      startWatcher();

      renameDir("old", "new");
      inAnyOrder([
        isRemoveEvent("old/file.txt"),
        isAddEvent("new/file.txt")
      ]);

      writeFile("new/file.txt", contents: "modified");
      expectModifyEvent("new/file.txt");
    });

    test('emits events for many nested files added at once', () {
      withPermutations((i, j, k) =>
          writeFile("sub/sub-$i/sub-$j/file-$k.txt"));

      createDir("dir");
      startWatcher(dir: "dir");
      renameDir("sub", "dir/sub");

      inAnyOrder(withPermutations((i, j, k)  =>
          isAddEvent("dir/sub/sub-$i/sub-$j/file-$k.txt")));
    });

    test('emits events for many nested files removed at once', () {
      withPermutations((i, j, k) =>
          writeFile("dir/sub/sub-$i/sub-$j/file-$k.txt"));

      createDir("dir");
      startWatcher(dir: "dir");

      // Rename the directory rather than deleting it because native watchers
      // report a rename as a single DELETE event for the directory, whereas
      // they report recursive deletion with DELETE events for every file in the
      // directory.
      renameDir("dir/sub", "sub");

      inAnyOrder(withPermutations((i, j, k) =>
          isRemoveEvent("dir/sub/sub-$i/sub-$j/file-$k.txt")));
    });

    test('emits events for many nested files moved at once', () {
      withPermutations((i, j, k) =>
          writeFile("dir/old/sub-$i/sub-$j/file-$k.txt"));

      createDir("dir");
      startWatcher(dir: "dir");
      renameDir("dir/old", "dir/new");

      inAnyOrder(unionAll(withPermutations((i, j, k) {
        return new Set.from([
          isRemoveEvent("dir/old/sub-$i/sub-$j/file-$k.txt"),
          isAddEvent("dir/new/sub-$i/sub-$j/file-$k.txt")
        ]);
      })));
    });

    test("emits events for many files added at once in a subdirectory with the "
        "same name as a removed file", () {
      writeFile("dir/sub");
      withPermutations((i, j, k) =>
          writeFile("old/sub-$i/sub-$j/file-$k.txt"));
      startWatcher(dir: "dir");

      deleteFile("dir/sub");
      renameDir("old", "dir/sub");

      var events = withPermutations((i, j, k)  =>
          isAddEvent("dir/sub/sub-$i/sub-$j/file-$k.txt"));
      events.add(isRemoveEvent("dir/sub"));
      inAnyOrder(events);
    });
  });
}
