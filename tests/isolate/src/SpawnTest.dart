// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("SpawnTest");
#import("dart:isolate");
#import("TestFramework.dart");

void test(TestExpectation expect) {
  SpawnedIsolate isolate = new SpawnedIsolate();
  expect.completes(isolate.spawn()).then((SendPort port) {
    port.call(42).then(expect.runs1((message) {
      Expect.equals(42, message);
      expect.succeeded();
    }));
  });
}

class SpawnedIsolate extends Isolate {

  SpawnedIsolate() : super() { }

  void main() {
    this.port.receive((message, SendPort replyTo) {
      Expect.equals(42, message);
      replyTo.send(42, null);
      this.port.close();
    });
  }

}

main() {
  runTests([test]);
}
