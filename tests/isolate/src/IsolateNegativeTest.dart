// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates are spawned.

#library('IsolateNegativeTest');
#import('dart:isolate');
#import('TestFramework.dart');

class IsolateNegativeTest extends Isolate {
  IsolateNegativeTest() : super();

  void main() {
    this.port.receive((ignored, replyTo) {
      replyTo.send("foo", null);
    });
  }
}

void test(TestExpectation expect) {
  expect.completes(new IsolateNegativeTest().spawn()).then((SendPort port) {
    port.call("foo").then(expect.runs1((message) {
      Expect.equals(true, "Expected fail");   // <=-------- Should fail here.
      expect.succeeded();
    }));
  });
}

main() {
  runTests([test]);
}
