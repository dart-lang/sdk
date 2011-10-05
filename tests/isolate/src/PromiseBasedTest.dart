// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("PromiseBasedTest");
#import("TestFramework.dart");

class TestIsolate extends Isolate {

  TestIsolate() : super();

  void main() {
    int seed = 0;
    this.port.receive((var message, SendPort replyTo) {
      if (seed == 0) {
        seed = message[0];
      } else {
        Promise<int> response = new Promise<int>();
        var proxy = new Proxy.forPort(replyTo);
        proxy.send([response]);
        response.complete(seed + message[0]);
        this.port.close();
      }
    });
  }

}

void test(TestExpectation expect) {
  Proxy proxy = new Proxy.forIsolate(new TestIsolate());
  proxy.send([42]);  // Seed the isolate.
  Promise promise = expect.completes(proxy.call([87])).then((int value) {
    Expect.equals(42 + 87, value);
    return 99;
  });
  expect.completes(promise).then((int value) {
    Expect.equals(99, value);
    expect.succeeded();
  });
}

void main() {
  runTests([test]);
}
