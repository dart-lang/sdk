// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library futures_test;
import "package:expect/expect.dart";
import 'dart:async';
import 'dart:isolate';

Future testWaitEmpty() {
  List<Future> futures = new List<Future>();
  return Future.wait(futures);
}

Future testCompleteAfterWait() {
  List<Future> futures = new List<Future>();
  Completer<Object> c = new Completer<Object>();
  futures.add(c.future);
  Future future = Future.wait(futures);
  c.complete(null);
  return future;
}

Future testCompleteBeforeWait() {
  List<Future> futures = new List<Future>();
  Completer c = new Completer();
  futures.add(c.future);
  c.complete(null);
  return Future.wait(futures);
}

Future testWaitWithMultipleValues() {
  List<Future> futures = new List<Future>();
  Completer c1 = new Completer();
  Completer c2 = new Completer();
  futures.add(c1.future);
  futures.add(c2.future);
  c1.complete(1);
  c2.complete(2);
  return Future.wait(futures).then((values) {
    Expect.listEquals([1, 2], values);
  });
}

Future testWaitWithSingleError() {
  List<Future> futures = new List<Future>();
  Completer c1 = new Completer();
  Completer c2 = new Completer();
  futures.add(c1.future);
  futures.add(c2.future);
  c1.complete();
  c2.completeError('correct error');

  return Future.wait(futures).then((_) {
    throw 'incorrect error';
  }).catchError((error) {
    Expect.equals('correct error', error);
  });
}

Future testWaitWithMultipleErrors() {
  List<Future> futures = new List<Future>();
  Completer c1 = new Completer();
  Completer c2 = new Completer();
  futures.add(c1.future);
  futures.add(c2.future);
  c1.completeError('correct error');
  c2.completeError('incorrect error 1');

  return Future.wait(futures).then((_) {
    throw 'incorrect error 2';
  }).catchError((error) {
    Expect.equals('correct error', error);
  });
}

Future testForEachEmpty() {
  return Future.forEach([], (_) {
    throw 'should not be called';
  });
}

Future testForEach() {
  var seen = <int>[];
  return Future.forEach([1, 2, 3, 4, 5], (n) {
    seen.add(n);
    return new Future.value();
  }).then((_) => Expect.listEquals([1, 2, 3, 4, 5], seen));
}

Future testForEachWithException() {
  var seen = <int>[];
  return Future.forEach([1, 2, 3, 4, 5], (n) {
    if (n == 4) throw 'correct exception';
    seen.add(n);
    return new Future.value();
  }).then((_) {
    throw 'incorrect exception';
  }).catchError((error) {
    Expect.equals('correct exception', error);
  });
}

main() {
  List<Future> futures = new List<Future>();

  futures.add(testWaitEmpty());
  futures.add(testCompleteAfterWait());
  futures.add(testCompleteBeforeWait());
  futures.add(testWaitWithMultipleValues());
  futures.add(testWaitWithSingleError());
  futures.add(testWaitWithMultipleErrors());
  futures.add(testForEachEmpty());
  futures.add(testForEach());
  futures.add(testForEachWithException());

  // Use a receive port for blocking the test.
  // Note that if the test fails, the program will not end.
  ReceivePort port = new ReceivePort();
  Future.wait(futures).then((List list) {
    Expect.equals(9, list.length);
    port.close();
  });
}
