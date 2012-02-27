// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// spawns multiple isolates and sends unresolved ports between them.
#library('unresolved_ports');
#import('dart:isolate');

// This test does the following:
//  - main spawns two isolates: 'tim' and 'beth'
//  - 'tim' spawns an isolate: 'bob'
//  - main starts a message chain:
//       main -> beth -> tim -> bob -> main
//    by giving 'beth' a send-port to 'tim'.

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
      + "\nBob says: we are all coming!", msg);
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
