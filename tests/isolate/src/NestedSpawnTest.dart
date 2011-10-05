// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can spawn other isolates.

#library('NestedSpawnTest');
#import('TestFramework.dart');

class Isolate1 extends Isolate {
  Isolate1() : super.heavy();

  void main() {
    this.port.receive((msg, replyTo) {
      Expect.equals("launch nested!", msg);
      new Isolate2().spawn().then((SendPort p) {
        p.call("alive?").receive((msg, ignored) {
          Expect.equals("and kicking", msg);
          replyTo.send(499, null);
          this.port.close();
        });
      });
    });
  }
}

class Isolate2 extends Isolate {
  Isolate2() : super.heavy();

  void main() {
    this.port.receive((msg, replyTo) {
      Expect.equals("alive?", msg);
      replyTo.send("and kicking", null);
      this.port.close();
    });
  }
}

test(TestExpectation expect) {
  expect.completes(new Isolate1().spawn()).then((SendPort port) {
    port.call("launch nested!").receive(expect.runs2((msg, ignored) {
      Expect.equals(499, msg);
      expect.succeeded();
    }));
  });
}

main() {
  runTests([test]);
}
