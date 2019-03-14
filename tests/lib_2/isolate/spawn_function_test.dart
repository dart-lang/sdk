// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of spawning an isolate from a function.
library spawn_tests;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

child(args) {
  var msg = args[0];
  var reply = args[1];
  reply.send('re: $msg');
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test('message - reply chain', () async {
    ReceivePort port = new ReceivePort();
    port.listen(expectAsync((msg) {
      port.close();
      expect(msg, equals('re: hi'));
    }));
    const String debugName = 'spawnedIsolate';
    final i =
        await Isolate.spawn(child, ['hi', port.sendPort], debugName: debugName);
    expect(i.debugName, debugName);
  });
}
