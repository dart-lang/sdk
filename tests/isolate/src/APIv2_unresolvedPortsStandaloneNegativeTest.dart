// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A negative test to ensure we are covering all the assertions and running to
// completion APIv2_unresolvedPortsStandaloneTest.
#library('unresolved_ports');
#import('dart:isolate');

bethIsolate(ReceivePort port) {
  port.receive((msg, reply) => msg[1].send(
        "${msg[0]}\nBeth says: Tim are you coming? And Bob?", reply));
}

timIsolate(ReceivePort port) {
  Isolate2 bob = new Isolate2.fromCode(bobIsolate);
  port.receive((msg, reply) => bob.sendPort.send(
        "$msg\nTim says: Can you tell 'main' that we are all coming?", reply));
}

bobIsolate(ReceivePort port) {
  port.receive((msg, reply) => reply.send(
        "$msg\nBob says: we are all coming!"));
}

main() {
  ReceivePort port = new ReceivePort();
  port.receive((msg, _) {
    Expect.equals("main says: Beth, find out if Tim is coming."
      + "\nBeth says: Tim are you coming? And Bob?"
      + "\nTim says: Can you tell 'main' that we are all coming?"
      + "\nBob says: we are NOT coming!", msg); // should be 'all', not 'NOT'
    port.close();
  });

  Isolate2 tim = new Isolate2.fromCode(timIsolate);
  Isolate2 beth = new Isolate2.fromCode(bethIsolate);

  beth.sendPort.send(
      // because tim is created asynchronously, here we are sending an
      // unresolved port:
      ["main says: Beth, find out if Tim is coming.", tim.sendPort],
      port.toSendPort());
}
