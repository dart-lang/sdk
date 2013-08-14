// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';

main() {
  initConfig();

  setUp(createSandbox);

  test('does not notify for files that already exist when started', () {
    // Make some pre-existing files.
    writeFile("a.txt");
    writeFile("b.txt");

    createWatcher();

    // Change one after the watcher is running.
    writeFile("b.txt", contents: "modified");

    // We should get a modify event for the changed file, but no add events
    // for them before this.
    expectModifyEvent("b.txt");
  });

  test('notifies when a file is added', () {
    createWatcher();
    writeFile("file.txt");
    expectAddEvent("file.txt");
  });

  test('notifies when a file is modified', () {
    writeFile("file.txt");
    createWatcher();
    writeFile("file.txt", contents: "modified");
    expectModifyEvent("file.txt");
  });

  test('notifies when a file is removed', () {
    writeFile("file.txt");
    createWatcher();
    deleteFile("file.txt");
    expectRemoveEvent("file.txt");
  });

  test('notifies when a file is moved', () {
    writeFile("old.txt");
    createWatcher();
    renameFile("old.txt", "new.txt");
    expectAddEvent("new.txt");
    expectRemoveEvent("old.txt");
  });

  test('notifies when a file is modified multiple times', () {
    writeFile("file.txt");
    createWatcher();
    writeFile("file.txt", contents: "modified");
    expectModifyEvent("file.txt");
    writeFile("file.txt", contents: "modified again");
    expectModifyEvent("file.txt");
  });

  test('does not notify if the file contents are unchanged', () {
    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "before");
    createWatcher();
    writeFile("a.txt", contents: "same");
    writeFile("b.txt", contents: "after");
    expectModifyEvent("b.txt");
  });

  test('does not notify if the modification time did not change', () {
    writeFile("a.txt", contents: "before");
    writeFile("b.txt", contents: "before");
    createWatcher();
    writeFile("a.txt", contents: "after", updateModified: false);
    writeFile("b.txt", contents: "after");
    expectModifyEvent("b.txt");
  });

  test('watches files in subdirectories', () {
    createWatcher();
    writeFile("a/b/c/d/file.txt");
    expectAddEvent("a/b/c/d/file.txt");
  });

  test('watches a directory created after the watcher', () {
    // Watch a subdirectory that doesn't exist yet.
    createWatcher(dir: "a");

    // This implicity creates it.
    writeFile("a/b/c/d/file.txt");
    expectAddEvent("a/b/c/d/file.txt");
  });

  test('when the watched directory is deleted, removes all files', () {
    writeFile("dir/a.txt");
    writeFile("dir/b.txt");

    createWatcher(dir: "dir");

    deleteDir("dir");
    expectRemoveEvents(["dir/a.txt", "dir/b.txt"]);
  });
}
