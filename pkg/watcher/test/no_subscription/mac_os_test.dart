// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:watcher/src/directory_watcher/mac_os.dart';
import 'package:watcher/watcher.dart';

import 'shared.dart';
import '../utils.dart';

// This is currently failing due to issue 14793. The reason is fairly complex:
//
// 1. As part of the test, an "unwatched.txt" file is created while there are no
//    active watchers on the containing directory.
//
// 2. A watcher is then added.
//
// 3. The watcher lists the contents of the directory and notices that
//    "unwatched.txt" already exists.
//
// 4. Since FSEvents reports past changes (issue 14373), the IO event stream
//    emits a CREATED event for "unwatched.txt".
//
// 5. Due to issue 14793, the watcher cannot trust that this is really a CREATED
//    event and checks the status of "unwatched.txt" on the filesystem against
//    its internal state.
//
// 6. "unwatched.txt" exists on the filesystem and the watcher knows about it
//    internally as well. It assumes this means that the file was modified.
//
// 7. The watcher emits an unexpected MODIFIED event for "unwatched.txt",
//    causing the test to fail.
//
// Once issue 14793 is fixed, this will no longer be the case and the test will
// work again.

main() {
  initConfig();

  watcherFactory = (dir) => new MacOSDirectoryWatcher(dir);

  setUp(createSandbox);

  sharedTests();
}