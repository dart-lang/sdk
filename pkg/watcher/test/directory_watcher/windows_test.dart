// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/src/directory_watcher/windows.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

main() {
  initConfig();

  watcherFactory = (dir) => new WindowsDirectoryWatcher(dir);

  setUp(createSandbox);

  sharedTests();

  test('DirectoryWatcher creates a WindowsDirectoryWatcher on Windows', () {
    expect(new DirectoryWatcher('.'),
        new isInstanceOf<WindowsDirectoryWatcher>());
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
}

