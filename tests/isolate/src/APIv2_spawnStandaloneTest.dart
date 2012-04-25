// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of spawning an isolate from a function.
#library('spawn_tests');
#import('dart:isolate');

child() {
  port.receive((msg, reply) => reply.send('re: $msg'));
}

main() {
  ReceivePort port = new ReceivePort();
  port.receive((msg, _) {
    Expect.equals('re: hi', msg);
    port.close();
  });

  SendPort s = spawnFunction(child);
  s.send('hi', port.toSendPort());
}
