// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library futures_test;
import 'dart:isolate';

Future testWaitEmpty() {
  List<Future> futures = new List<Future>();
  return Futures.wait(futures);
}

Future testCompleteAfterWait() {
  List<Future> futures = new List<Future>();
  Completer<Object> c = new Completer<Object>();
  futures.add(c.future);
  Future future = Futures.wait(futures);
  c.complete(null);
  return future;
}

Future testCompleteBeforeWait() {
  List<Future> futures = new List<Future>();
  Completer c = new Completer();
  futures.add(c.future);
  c.complete(null);
  return Futures.wait(futures);
}

Future testForEachEmpty() {
  return Futures.forEach([], (_) => throw 'should not be called');
}

Future testForEach() {
  var seen = <int>[];
  return Futures.forEach([1, 2, 3, 4, 5], (n) {
    seen.add(n);
    return new Future.immediate(null);
  }).transform((_) => Expect.listEquals([1, 2, 3, 4, 5], seen));
}

Future testForEachWithException() {
  var seen = <int>[];
  return Futures.forEach([1, 2, 3, 4, 5], (n) {
    if (n == 4) throw 'correct exception';
    seen.add(n);
    return new Future.immediate(null);
  }).transform((_) => throw 'incorrect exception').transformException((e) {
    Expect.equals('correct exception', e);
  });
}

main() {
  List<Future> futures = new List<Future>();

  futures.add(testWaitEmpty());
  futures.add(testCompleteAfterWait());
  futures.add(testCompleteBeforeWait());
  futures.add(testForEachEmpty());
  futures.add(testForEach());

  // Use a receive port for blocking the test. 
  // Note that if the test fails, the program will not end.
  ReceivePort port = new ReceivePort();
  Futures.wait(futures).then((List list) {
    Expect.equals(5, list.length);
    port.close();
  });
}
