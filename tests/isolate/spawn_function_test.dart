// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of spawning an isolate from a function.
#library('spawn_tests');
#import('dart:isolate');
#import('../../pkg/unittest/unittest.dart');

child() {
  port.receive((msg, reply) => reply.send('re: $msg'));
}

main() {
  test('message - reply chain', () {
    ReceivePort port = new ReceivePort();
    port.receive(expectAsync2((msg, _) {
      port.close();
      expect(msg, equals('re: hi'));
    }));

    SendPort s = spawnFunction(child);
    s.send('hi', port.toSendPort());
  });
}
