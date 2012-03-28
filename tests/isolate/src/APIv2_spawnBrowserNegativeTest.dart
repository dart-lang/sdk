// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Negative test to make sure that we are reaching all assertions.
#library('spawn_tests');
#import('../../../lib/unittest/unittest_dom.dart');
#import('dart:dom'); // import added so test.dart can treat this as a webtest.
#import('dart:isolate');

child() {
  port.receive((msg, reply) => reply.send('re: $msg'));
}

main() {
  asyncTest('message - reply chain', 1, () {
    ReceivePort port = new ReceivePort();
    port.receive((msg, _) {
      expect(msg).equals('re: hello'); // should be hi, not hello
      port.close();
      callbackDone();
    });

    SendPort s = spawnFunction(child);
    s.send('hi', port.toSendPort());
  });
}
