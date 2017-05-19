// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class A {
  const A();
}

class B extends A {
  const B();
}

main() {
  asyncStart();
  // Correct behavior.
  for (var eq in [null, (a, b) => a == b]) {
    checkStream(mkSingleStream, eq, "single");
    checkBroadcastStream(mkBroadcastStream, eq, "broadcast");
    checkBroadcastStream(
        () => mkSingleStream().asBroadcastStream(), eq, "asBroadcast");
  }

  // Regression test. Multiple listens on the same broadcast distinct stream.
  var stream = mkBroadcastStream().distinct();
  expectStream(stream, [1, 2, 3, 2], "broadcast.distinct#1");
  expectStream(stream, [1, 2, 3, 2], "broadcast.distinct#2");

  // Doesn't ignore equality.
  expectStream(
      new Stream.fromIterable([1, 2, 1, 3, 3]).distinct((a, b) => false),
      [1, 2, 1, 3, 3],
      "kFalse");
  expectStream(
      new Stream.fromIterable([1, 2, 1, 3, 3]).distinct((a, b) => true),
      [1],
      "kTrue");
  expectStream(
      new Stream.fromIterable([1, 2, 1, 3, 3]).distinct((a, b) => a != b),
      [1, 1],
      "neq");
  expectStream(
      new Stream.fromIterable([1, 2, 1, 3, 3]).distinct((a, b) => 2 == b),
      [1, 1, 3, 3],
      "is2");
  // Forwards errors as errors.
  expectStream(
      new Stream.fromIterable([1, "E1", 2, "E2", 2, 3])
          .map((v) => (v is String) ? (throw v) : v) // Make strings errors.
          .distinct()
          .transform(reifyErrors),
      [1, "[E1]", 2, "[E2]", 3],
      "errors");
  // Equality throwing acts like error.
  expectStream(
      new Stream.fromIterable([1, "E1", 1, 2, "E2", 3])
          .distinct((a, b) => (b is String) ? (throw b) : (a == b))
          .transform(reifyErrors),
      [1, "[E1]", 2, "[E2]", 3],
      "eq-throws");
  // Operator== throwing acts like error.
  expectStream(
      new Stream.fromIterable([1, 1, 2, 2, 1, 3])
          .map((v) => new T(v))
          .distinct()
          .transform(reifyErrors)
          .map((v) => v is T ? v.value : "$v"),
      [1, "[2]", "[2]", 3],
      "==-throws");
  asyncEnd();
}

checkStream(mkStream, eq, name) {
  expectStream(mkStream().distinct(eq), [1, 2, 3, 2], "$name.distinct");
  expectStream(mkStream().expand((e) => [e, e]).distinct(eq), [1, 2, 3, 2],
      "$name.expand.distinct");
  expectStream(mkStream().where((x) => x != 3).distinct(eq), [1, 2],
      "$name.where.distinct");
}

checkBroadcastStream(mkStream, eq, name) {
  var stream = mkStream();
  // Run all the tests, multiple times each.
  checkStream(() => stream, eq, "$name#1");
  checkStream(() => stream, eq, "$name#2");
}

mkSingleStream() async* {
  yield 1;
  yield 2;
  yield 3;
  yield 2;
}

mkBroadcastStream() {
  var c = new StreamController.broadcast();
  c.onListen = () {
    c.addStream(mkSingleStream()).whenComplete(c.close);
  };
  return c.stream;
}

expectStream(stream, list, [name]) {
  asyncStart();
  return stream.toList().then((events) {
    Expect.listEquals(list, events, name);
    asyncEnd();
  });
}

// Class where operator== throws.
class T {
  final int value;
  T(this.value);
  int get hashCode => value.hashCode;
  bool operator ==(Object other) =>
      other is T && ((other.value == 2) ? throw 2 : (value == other.value));
}

final reifyErrors =
    new StreamTransformer.fromHandlers(handleError: (e, s, sink) {
  sink.add("[$e]");
});
