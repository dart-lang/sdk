// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("StaticStateTest");
#import("dart:isolate");
#import('../../lib/unittest/unittest.dart');

class TestIsolate extends Isolate {

  TestIsolate() : super();

  void main() {
    Expect.equals(null, state);
    this.port.receive((var message, SendPort replyTo) {
      String old = state;
      state = message;
      replyTo.send(old, null);
      if (message == "exit") {
        this.port.close();
      }
    });
  }

  static String state;

}

void main() {
  test("static state is not shared between isolates", () {
    Expect.equals(null, TestIsolate.state);
    TestIsolate.state = "foo";
    Expect.equals("foo", TestIsolate.state);

    new TestIsolate().spawn().then(expectAsync1((SendPort remote) {
      remote.call("bar").then(expectAsync1((reply) {
        Expect.equals("foo", TestIsolate.state);
        Expect.equals(null, reply);

        TestIsolate.state = "baz";
        remote.call("exit").then(expectAsync1((reply) {
          Expect.equals("baz", TestIsolate.state);
          Expect.equals("bar", reply);
        }));
      }));
    }));
  });
}
