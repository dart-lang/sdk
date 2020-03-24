// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Example of spawning an isolate from a function.
library spawn_tests;

import 'dart:isolate';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

isolateEntryPoint(args) {
  var msg = args[0];
  var sendPort = args[1];
  sendPort.send('re: $msg');
}

Future<void> main([args, port]) async {
  // message - reply chain
  const String debugName = 'spawnedIsolate';

  ReceivePort port = new ReceivePort();
  asyncStart();
  port.listen((msg) {
    port.close();
    Expect.equals(msg, 're: hi');
    asyncEnd();
  });

  // Start new isolate; paused so it's alive till we read the debugName.
  // If the isolate runs to completion, the isolate might get cleaned up
  // and debugName might be null.
  final isolate = await Isolate.spawn(isolateEntryPoint, ['hi', port.sendPort],
      paused: true, debugName: debugName);

  Expect.equals(isolate.debugName, debugName);
  isolate.resume(isolate.pauseCapability!);
}
