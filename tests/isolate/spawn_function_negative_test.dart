// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Negative test to make sure that we are reaching all assertions.
#library('spawn_tests');
#import('dart:isolate');
#import('../../pkg/unittest/lib/unittest.dart');

child() {
  port.receive((msg, reply) => reply.send('re: $msg'));
}

main() {
  test('message - reply chain', () {
    ReceivePort port = new ReceivePort();
    port.receive(expectAsync2((msg, _) {
      port.close();
      expect(msg, equals('re: hello')); // should be hi, not hello
    }));

    SendPort s = spawnFunction(child);
    s.send('hi', port.toSendPort());
  });
}
