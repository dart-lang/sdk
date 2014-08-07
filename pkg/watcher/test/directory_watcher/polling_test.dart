// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

void main() {
  initConfig();

  // Use a short delay to make the tests run quickly.
  watcherFactory = (dir) => new PollingDirectoryWatcher(dir,
      pollingDelay: new Duration(milliseconds: 100));

  setUp(createSandbox);

  sharedTests();

  test('does not notify if the modification time did not change', () {
    writeFile("a.txt", contents: "before");
    writeFile("b.txt", contents: "before");
    startWatcher();
    writeFile("a.txt", contents: "after", updateModified: false);
    writeFile("b.txt", contents: "after");
    expectModifyEvent("b.txt");
  });
}
