// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Example of spawning an isolate from a function.
library spawn_tests;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

isolateEntryPoint(args) {
  var msg = args[0];
  var sendPort = args[1];
  sendPort.send('re: $msg');
}

void main([args, port]) {
  if (testRemote(main, port)) {
    return;
  }

  test('message - reply chain', () async {
    const String debugName = 'spawnedIsolate';

    ReceivePort port = new ReceivePort();
    port.listen(expectAsync((msg) {
      port.close();
      expect(msg, equals('re: hi'));
    }));

    // Start new isolate; paused so it's alive till we read the debugName.
    // If the isolate runs to completion, the isolate might get cleaned up
    // and debugName might be null.
    final isolate = await Isolate.spawn(
        isolateEntryPoint, ['hi', port.sendPort],
        paused: true, debugName: debugName);

    expect(isolate.debugName, debugName);

    isolate.resume(isolate.pauseCapability);
  });
}
