// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";

class TypeTest<T, NT> {
  void call(object, name) {
    Expect.isTrue(object is T, "$name is $T");
    Expect.isFalse(object is NT, "$name is! $NT");
  }
}

main() {
  var checkIntStream = new TypeTest<Stream<int>, Stream<String>>();
  var checkIntFuture = new TypeTest<Future<int>, Future<String>>();
  var checkBoolFuture = new TypeTest<Future<bool>, Future<String>>();
  var checkStringFuture = new TypeTest<Future<String>, Future<int>>();
  var checkIntSetFuture = new TypeTest<Future<Set<int>>, Future<Set<String>>>();
  var checkIntListFuture =
      new TypeTest<Future<List<int>>, Future<List<String>>>();
  var checkIntSubscription =
      new TypeTest<StreamSubscription<int>, StreamSubscription<String>>();

  // Generic function used as parameter for, e.g., `skipWhile` and `reduce`.
  f([_1, _2]) => throw "unreachable";

  bool testIntStream(stream(), name, int recursionDepth) {
    checkIntStream(stream(), name);
    if (recursionDepth > 0) {
      checkIntSubscription(stream().listen(null), "$name.listen");

      checkIntFuture(stream().first, "$name.first");
      checkIntFuture(stream().last, "$name.last");
      checkIntFuture(stream().single, "$name.single");
      checkIntFuture(stream().singleWhere(f), "$name.singleWhere");
      checkIntFuture(stream().elementAt(2), "$name.elementAt");
      checkIntFuture(stream().reduce(f), "$name.reduce");
      checkIntListFuture(stream().toList(), "$name.toList");
      checkIntSetFuture(stream().toSet(), "$name.toSert");

      checkIntFuture(stream().length, "$name.length");
      checkBoolFuture(stream().isEmpty, "$name.is");
      checkBoolFuture(stream().any(f), "$name.any");
      checkBoolFuture(stream().every(f), "$name.every");
      checkBoolFuture(stream().contains(null), "$name.contains");
      checkStringFuture(stream().join(), "$name.join");

      var n = recursionDepth - 1;
      testIntStream(() => stream().where(f), "$name.where", n);
      testIntStream(() => stream().take(2), "$name.take", n);
      testIntStream(() => stream().takeWhile(f), "$name.takeWhile", n);
      testIntStream(() => stream().skip(2), "$name.skip", n);
      testIntStream(() => stream().skipWhile(f), "$name.skipWhile", n);
      testIntStream(() => stream().distinct(f), "$name.distinct", n);
      testIntStream(() => stream().handleError(f), "$name.handleError", n);
      testIntStream(
          () => stream().asBroadcastStream(), "$name.asBroadcastStream", n);
    }
  }

  testIntStream(() => new StreamController<int>().stream, "Stream<int>", 3);
  testIntStream(() => new StreamController<int>.broadcast().stream,
      "BroadcastStream<int>", 3);
}
