// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that heavy and light isolates can be mixed.

#library('MixedTest');
#import("dart:isolate");
#import('TestFramework.dart');

class IsolateA extends Isolate {
  IsolateA() : super.heavy();

  void main() {
    this.port.receive((msg, replyTo) {
      Expect.equals("launch nested!", msg);
      new IsolateB().spawn().then((SendPort p) {
        p.call("alive?").then((msg) {
          Expect.equals("and kicking", msg);
          replyTo.send(499, null);
          this.port.close();
        });
      });
    });
  }
}

class IsolateB extends Isolate {
  IsolateB() : super.light();

  void main() {
    this.port.receive((msg, replyTo) {
      Expect.equals("alive?", msg);
      replyTo.send("and kicking", null);
      this.port.close();
    });
  }
}

test(TestExpectation expect) {
  expect.completes(new IsolateA().spawn()).then((SendPort port) {
    port.call("launch nested!").then(expect.runs1((msg) {
      Expect.equals(499, msg);
      expect.succeeded();
    }));
  });
}

main() {
  runTests([test]);
}
