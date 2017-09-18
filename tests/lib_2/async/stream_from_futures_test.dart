// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import 'package:async_helper/async_helper.dart';

main() {
  asyncStart();

  testValues();
  testErrors();
  testMixed();
  testOrdering();
  testEmpty();
  testPrecompleted();

  asyncEnd();
}

void testValues() {
  asyncStart();
  var cs = new List.generate(3, (_) => new Completer());
  var stream = new Stream.fromFutures(cs.map((x) => x.future));
  var result = stream.toList();

  result.then((list) {
    Expect.listEquals([1, 2, 3], list);
    asyncEnd();
  });

  cs[1].complete(1);
  cs[2].complete(2);
  cs[0].complete(3);
}

void testErrors() {
  asyncStart();
  var cs = new List.generate(3, (_) => new Completer());
  var stream = new Stream.fromFutures(cs.map((x) => x.future));

  int counter = 0;
  stream.listen((_) {
    Expect.fail("unexpected value");
  }, onError: (e) {
    Expect.equals(++counter, e);
  }, onDone: () {
    Expect.equals(3, counter);
    asyncEnd();
  });

  cs[1].completeError(1);
  cs[2].completeError(2);
  cs[0].completeError(3);
}

void testMixed() {
  asyncStart();
  var cs = new List.generate(3, (_) => new Completer());
  var stream = new Stream.fromFutures(cs.map((x) => x.future));

  int counter = 0;
  stream.listen((v) {
    Expect.isTrue(counter == 0 || counter == 2);
    Expect.equals(++counter, v);
  }, onError: (e) {
    Expect.equals(++counter, 2);
    Expect.equals(2, e);
  }, onDone: () {
    Expect.equals(3, counter);
    asyncEnd();
  });

  cs[1].complete(1);
  cs[2].completeError(2);
  cs[0].complete(3);
}

void testOrdering() {
  // The output is in completion order, not affected by the input future order.
  test(n1, n2, n3) {
    asyncStart();
    var cs = new List.generate(3, (_) => new Completer());
    var stream = new Stream.fromFutures(cs.map((x) => x.future));
    var result = stream.toList();

    result.then((list) {
      Expect.listEquals([1, 2, 3], list);
      asyncEnd();
    });

    cs[n1].complete(1);
    cs[n2].complete(2);
    cs[n3].complete(3);
  }

  test(0, 1, 2);
  test(0, 2, 1);
  test(1, 0, 2);
  test(1, 2, 0);
  test(2, 0, 1);
  test(2, 1, 0);
}

void testEmpty() {
  asyncStart();
  var stream = new Stream.fromFutures([]);

  stream.listen((_) {
    Expect.fail("unexpected value");
  }, onError: (e) {
    Expect.fail("unexpected error");
  }, onDone: () {
    asyncEnd();
  });
}

void testPrecompleted() {
  asyncStart();
  var stream = new Stream.fromFutures(
      new Iterable.generate(3, (v) => new Future.value(v + 1)));
  var expected = new Set.from([1, 2, 3]);
  stream.listen((v) {
    Expect.isTrue(expected.contains(v));
    expected.remove(v);
  }, onDone: () {
    Expect.isTrue(expected.isEmpty);
    asyncEnd();
  });
}
