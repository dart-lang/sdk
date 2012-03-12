// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing isolate communication with
// typed objects.
// VMOptions=--enable_type_checks --enable_asserts

#library("TypedMessageTest");
#import("dart:isolate");

class TypedMessageTest {
  static void testMain() {
    LogClient.test();
  }
}


class LogClient {
  static void test() {
    new LogIsolate().spawn().then((SendPort remote) {

      List<int> msg = new List<int>(5);
      for (int i = 0; i < 5; i++) {
        msg[i] = i;
      }
      remote.call(msg).then((int message) {
        Expect.equals(1, message);
      });
    });
  }
}


class LogIsolate extends Isolate {
  LogIsolate() : super() {}

  void main() {
    print("Starting log server.");

    this.port.receive((List<int> message, SendPort replyTo) {
      print("Log $message");
      Expect.equals(5, message.length);
      Expect.equals(0, message[0]);
      Expect.equals(1, message[1]);
      Expect.equals(2, message[2]);
      Expect.equals(3, message[3]);
      Expect.equals(4, message[4]);
      this.port.close();
      replyTo.send(1, null);
      print("Stopping log server.");
    });
  }
}

main() {
  TypedMessageTest.testMain();
}
