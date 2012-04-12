// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// spawns multiple isolates and sends unresolved ports between them.
#library('unresolved_ports');
#import('dart:dom'); // import added so test.dart can treat this as a webtest.
#import('dart:isolate');
#import('../../../lib/unittest/unittest.dart');
#import('../../../lib/unittest/dom_config.dart');

// This is similar to APIv2_unresolvedPortsStandaloneTest but using
// 'unittest.dart' so it can run to completion in browsers.

bethIsolate() {
  port.receive((msg, reply) => msg[1].send(
        '${msg[0]}\nBeth says: Tim are you coming? And Bob?', reply));
}

timIsolate() {
  SendPort bob = spawnFunction(bobIsolate);
  port.receive((msg, reply) => bob.send(
        '$msg\nTim says: Can you tell "main" that we are all coming?', reply));
}

bobIsolate() {
  port.receive((msg, reply) => reply.send(
        '$msg\nBob says: we are all coming!'));
}

main() {
  useDomConfiguration();
  asyncTest('Message chain with unresolved ports', 1, () {
    ReceivePort port = new ReceivePort();
    port.receive((msg, _) {
      expect(msg).equals('main says: Beth, find out if Tim is coming.'
        + '\nBeth says: Tim are you coming? And Bob?'
        + '\nTim says: Can you tell "main" that we are all coming?'
        + '\nBob says: we are all coming!');
      port.close();
      callbackDone();
    });

    SendPort tim = spawnFunction(timIsolate);
    SendPort beth = spawnFunction(bethIsolate);

    beth.send(
        // because tim is created asynchronously, here we are sending an
        // unresolved port:
        ['main says: Beth, find out if Tim is coming.', tim],
        port.toSendPort());
  });
}
