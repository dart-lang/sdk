// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of spawning an isolate from a URI
library spawn_tests;

import 'dart:isolate';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncTest(() async {
    const String debugName = 'spawnedIsolate';

    final exitPort = ReceivePort();

    final port = new ReceivePort();

    asyncStart();
    port.listen((msg) {
      Expect.equals('re: hi', msg);
      port.close();
      asyncEnd();
    });

    // Start new isolate; paused so it's alive till we read the debugName.
    // If the isolate runs to completion, the isolate might get cleaned up
    // and debugName might be null.
    final isolate = await Isolate.spawnUri(
      Uri.parse('spawn_uri_child_isolate.dart'),
      ['hi'],
      port.sendPort,
      paused: true,
      debugName: debugName,
      onExit: exitPort.sendPort,
    );

    Expect.equals(debugName, isolate.debugName);

    isolate.resume(isolate.pauseCapability!);

    // Explicitly await spawned isolate exit to enforce main isolate not
    // completing (and the stand-alone runtime exiting) before the spawned
    // isolate is done.
    await exitPort.first;
  });
}
