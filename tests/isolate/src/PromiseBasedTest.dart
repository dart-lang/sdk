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
      //print("Got ${message[0]}");
      if (seed == 0) {
        seed = message[0];
      } else {
        Promise<int> response = new Promise<int>();
        var proxy = new Proxy.forPort(replyTo);
        //print("send to proxy");
        proxy.send([response]);
        //print("sent");
        response.complete(seed + message[0]);
        this.port.close();
      }
    });
  }

}

void test(TestExpectation expect) {
  Proxy proxy = new Proxy.forIsolate(new TestIsolate());
  proxy.send([42]);  // Seed the isolate.
  Promise<int> result = new PromiseProxy<int>(proxy.call([87]));
  Promise promise = expect.completes(result).then((int value) {
    //print("expect 1: $value");
    Expect.equals(42 + 87, value);
    return 99;
  });
  expect.completes(promise).then((int value) {
    //print("expect 2: $value");
    Expect.equals(99, value);
    expect.succeeded();
  });
}

void expandedTest(TestExpectation expect) {
  Proxy proxy = new Proxy.forIsolate(new TestIsolate());
  proxy.send([42]);  // Seed the isolate.
  Promise<SendPort> sendCompleter = proxy.call([87]);
  Promise<int> result = new Promise<int>();
  ReceivePort completer = new ReceivePort.singleShot();
  completer.receive((var msg, SendPort _) {
    //print("test completer");
    result.complete(msg[0]);
  });
  sendCompleter.addCompleteHandler((SendPort port) {
    //print("test send");
    port.send([completer.toSendPort()], null);
  });
  Promise promise = expect.completes(result).then((int value) {
    //print("expect 1: $value");
    Expect.equals(42 + 87, value);
    return 99;
  });
  expect.completes(promise).then((int value) {
    //print("expect 2: $value");
    Expect.equals(99, value);
    expect.succeeded();
  });
}

void main() {
  runTests([test, expandedTest]);
}
