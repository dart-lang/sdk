// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verify that on Windows FileSystemEntity.watch does not enter incorrect state
// after overflow (https://dartbug.com/61378). On other platforms we just
// expect watcher to never experience overflow receive events without issues.
//
// This was happening because Dart side of things was using raw addresses of
// DirectoryWatchHandle's created by native allocator as keys in a map
// inside _FileSystemWatcher implementation without ensuring that map is cleared
// before native memory is freed and reused for another similar object -
// thus making Dart side confuse two unrelated entities.

import 'dart:async';
import 'dart:io';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

var eventsSeen = 0;
var restartedTimes = 0;

Future<void> main() async {
  asyncStart();
  final temp = Directory.systemTemp.createTempSync('regress-61378');
  // Long file name to consume more space in the OS buffer which contains
  // file system events.
  final file = File('${temp.path}/file'.padRight(255, 'a'));
  try {
    startWatcher(temp);
    // Iteration numbers are selected based on experiments to maximize the
    // chance of error without significantly increase test running time.
    for (var times = 0; times < 20; ++times) {
      eventsSeen = 0;
      // Cause the watcher buffer to fill in a sync block.
      for (var i = 0; i < 200; ++i) {
        file.writeAsStringSync('$i');
      }
      // Allow async processing so the error has chance to happen.
      await Future.delayed(Duration(milliseconds: 100));
      if (Platform.isWindows) {
        Expect.isTrue(restartedTimes > 0, 'Expected some restarts to happen');
      }
      Expect.isTrue(eventsSeen > 0, 'Watcher did not get any events');
    }
    await subscription.cancel();
    asyncEnd();
  } finally {
    temp.deleteSync(recursive: true);
  }
}

late StreamSubscription subscription;

void startWatcher(Directory temp) {
  subscription = temp.watch().listen(
    (e) {
      ++eventsSeen;
    },
    onError: (e) async {
      restartedTimes++;
      await subscription.cancel();
      startWatcher(temp);
    },
    onDone: () {
      Expect.fail('Not expecting DONE.');
    },
  );
}
