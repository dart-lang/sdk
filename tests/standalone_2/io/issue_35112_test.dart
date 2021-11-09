// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'test_utils.dart' show withTempDir;

main() async {
  // Verify that File.setLastAccessed does *not* trigger a FileSystemModifyEvent
  // with FileSystemModifyEvent.contentChanged == true.
  await withTempDir('issue_35112', (Directory tempDir) async {
    File file = new File("${tempDir.path}/file.tmp");
    file.createSync();

    final eventCompleter = new Completer<FileSystemEvent>();
    StreamSubscription subscription;
    subscription = tempDir.watch().listen((FileSystemEvent event) {
      if (event is FileSystemModifyEvent && event.contentChanged) {
        eventCompleter.complete(event);
      }
      subscription?.cancel();
    });

    file.setLastAccessedSync(DateTime.now().add(Duration(days: 3)));
    Timer(Duration(seconds: 1), () {
      eventCompleter.complete(null);
      subscription?.cancel();
    });
    ;
    FileSystemEvent event = await eventCompleter.future;
    Expect.isNull(event,
        "No event should be triggered or .contentChanged should equal false");
  });
}
