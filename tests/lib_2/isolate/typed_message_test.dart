// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing isolate communication with
// typed objects.
// VMOptions=--checked

library TypedMessageTest;

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:isolate";

void logMessages(SendPort replyTo) {
  print("Starting log server.");
  ReceivePort port = new ReceivePort();
  replyTo.send(port.sendPort);
  port.first.then((List<int> message) {
    print("Log $message");
    Expect.equals(5, message.length);
    Expect.equals(0, message[0]);
    Expect.equals(1, message[1]);
    Expect.equals(2, message[2]);
    Expect.equals(3, message[3]);
    Expect.equals(4, message[4]);
    port.close();
    replyTo.send(1);
    print("Stopping log server.");
  });
}

main() {
  asyncStart();
  ReceivePort receivePort = new ReceivePort();
  Future<Isolate> remote = Isolate.spawn(logMessages, receivePort.sendPort);
  var msg = <int>[0, 1, 2, 3, 4];
  StreamIterator iterator = new StreamIterator(receivePort);
  iterator.moveNext().then((b) {
    SendPort sendPort = iterator.current;
    sendPort.send(msg);
    return iterator.moveNext();
  }).then((b) {
    Expect.equals(1, iterator.current);
    receivePort.close();
    asyncEnd();
  });
}
