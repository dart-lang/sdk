// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// negative test to ensure that API_unresolvedPortsTest works.
library unresolved_ports;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

bethIsolate() {
  port.receive(expectAsync2((msg, reply) => msg[1].send(
        '${msg[0]}\nBeth says: Tim are you coming? And Bob?', reply)));
}

timIsolate() {
  SendPort bob = spawnFunction(bobIsolate);
  port.receive(expectAsync2((msg, reply) => bob.send(
        '$msg\nTim says: Can you tell "main" that we are all coming?', reply)));
}

bobIsolate() {
  port.receive(expectAsync2((msg, reply) => reply.send(
        '$msg\nBob says: we are all coming!')));
}

main() {
  test('Message chain with unresolved ports', () {
    ReceivePort port = new ReceivePort();
    port.receive(expectAsync2((msg, _) {
      expect(msg, equals('main says: Beth, find out if Tim is coming.'
        + '\nBeth says: Tim are you coming? And Bob?'
        + '\nTim says: Can you tell "main" that we are all coming?'
        + '\nBob says: we are NOT coming!')); // should be 'all', not 'NOT'
      port.close();
    }));

    SendPort tim = spawnFunction(timIsolate);
    SendPort beth = spawnFunction(bethIsolate);

    beth.send(
        // because tim is created asynchronously, here we are sending an
        // unresolved port:
        ['main says: Beth, find out if Tim is coming.', tim],
        port.toSendPort());
  });
}

