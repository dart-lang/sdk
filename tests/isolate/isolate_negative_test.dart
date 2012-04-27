// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates are spawned.

#library('IsolateNegativeTest');
#import('dart:isolate');
#import('../../lib/unittest/unittest.dart');

class IsolateNegativeTest extends Isolate {
  IsolateNegativeTest() : super();

  void main() {
    this.port.receive((ignored, replyTo) {
      replyTo.send("foo", null);
    });
  }
}

main() {
  test("ensure isolate code is executed", () {
    new IsolateNegativeTest().spawn().then(expectAsync1((SendPort port) {
      port.call("foo").then(expectAsync1((message) {
        Expect.equals(true, "Expected fail");   // <=-------- Should fail here.
      }));
    }));
  });
}
