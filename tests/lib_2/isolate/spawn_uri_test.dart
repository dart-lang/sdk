// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Example of spawning an isolate from a URI
library spawn_tests;

import 'dart:isolate';
import 'package:async_helper/async_minitest.dart';

main() {
  test('isolate fromUri - send and reply', () async {
    const String debugName = 'spawnedIsolate';

    final exitPort = ReceivePort();

    final port = new ReceivePort();
    port.listen(expectAsync((msg) {
      expect(msg, equals('re: hi'));
      port.close();
    }));

    // Start new isolate; paused so it's alive till we read the debugName.
    // If the isolate runs to completion, the isolate might get cleaned up
    // and debugName might be null.
    final isolate = await Isolate.spawnUri(
        Uri.parse('spawn_uri_child_isolate.dart'), ['hi'], port.sendPort,
        paused: true, debugName: debugName, onExit: exitPort.sendPort);

    expect(isolate.debugName, debugName);

    isolate.resume(isolate.pauseCapability);

    // Explicitly await spawned isolate exit to enforce main isolate not
    // completing (and the stand-alone runtime exiting) before the spawned
    // isolate is done.
    await exitPort.first;
  });
}
