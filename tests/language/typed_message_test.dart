// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing isolate communication with
// typed objects.
// VMOptions=--checked

library TypedMessageTest;
import "dart:isolate";

void logMessages() {
  print("Starting log server.");
  port.receive((List<int> message, SendPort replyTo) {
    print("Log $message");
    Expect.equals(5, message.length);
    Expect.equals(0, message[0]);
    Expect.equals(1, message[1]);
    Expect.equals(2, message[2]);
    Expect.equals(3, message[3]);
    Expect.equals(4, message[4]);
    port.close();
    replyTo.send(1, null);
    print("Stopping log server.");
  });
}

main() {
  SendPort remote = spawnFunction(logMessages);
  List<int> msg = new List<int>(5);
  for (int i = 0; i < 5; i++) {
    msg[i] = i;
  }
  remote.call(msg).then((int message) {
    Expect.equals(1, message);
  });
}
