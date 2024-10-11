// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that 'await' should check if the awaited value has a correct
// Future<T> type before awaiting it. A Future of incompatible type
// should not be awaited.
//
// Regression test for https://github.com/dart-lang/sdk/issues/49396.

// Requirements=nnbd-strong

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:expect/static_type_helper.dart';

class A {}

abstract class B<X> extends A implements Future<X> {
  Future<X> get fut;
  asStream() => fut.asStream();
  catchError(error, {test}) => fut.catchError(error, test: test);
  then<R>(onValue, {onError}) => fut.then(onValue, onError: onError);
  timeout(timeLimit, {onTimeout}) =>
      fut.timeout(timeLimit, onTimeout: onTimeout);
  whenComplete(action) => fut.whenComplete(action);
}

class C extends B<Object?> {
  final Future<Object?> fut = Future.value(CompletelyUnrelated());
}

class CompletelyUnrelated {}

class C1 extends A {}

class C2 extends B<C1> {
  final Future<C1> fut = Future.value(C1());
}

void main() async {
  final Object o = Future<Object?>.value();
  var o2 = await o; // Remains a future.
  o2.expectStaticType<Exactly<Object>>();
  Expect.isTrue(o2 is Future<Object?>);
  Expect.identical(o2, o);

  final FutureOr<Object> x = Future<Object?>.value();
  var x2 = await x; // Remains a future.
  x2.expectStaticType<Exactly<Object>>();
  Expect.isTrue(x2 is Future<Object?>);
  Expect.identical(x2, x);

  final FutureOr<Future<int>> y = Future<int>.value(1);
  var y2 = await y; // Remains a `Future<int>`.
  y2.expectStaticType<Exactly<Future<int>>>();
  Expect.isTrue(y2 is Future<int>);
  Expect.identical(y2, y);

  A a = C();
  var a2 = await a; // Remains an `A`.
  a2.expectStaticType<Exactly<A>>();
  Expect.isTrue(a2 is A);
  Expect.identical(a2, a);

  Future<void> f<X extends Object>(X x) async {
    var x2 = await x; // Remains a `Future<Object?>`.
    Expect.isTrue(x2 is Future<Object?>);
    Expect.identical(x2, x);
  }

  await f(Future<Object?>.value(null));

  Future<void> g<X extends A>(X x) async {
    var x2 = await x; // The future is awaited.
    Expect.isTrue(x2 is C1);
    Expect.notIdentical(x2, x);
  }

  await g<A>(C2());
}
