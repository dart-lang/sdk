// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import '../static_type_helper.dart';

// Regression test, exercising the behavior described in SDK issue 49396.

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
  Expect.type<Future<Object?>>(o2);
  Expect.identical(o, o2);

  final FutureOr<Object> x = Future<Object?>.value();
  var x2 = await x; // Remains a future.
  x2.expectStaticType<Exactly<Object>>();
  Expect.type<Future<Object?>>(x2);
  Expect.identical(x, x2);

  final FutureOr<Future<int>> y = Future<int>.value(1);
  var y2 = await y; // Remains a `Future<int>`.
  y2.expectStaticType<Exactly<Future<int>>>();
  Expect.type<Future<int>>(y2);
  Expect.identical(y, y2);

  A a = C();
  var a2 = await a; // Remains a `C` and a `Future<Object?>`.
  a2.expectStaticType<Exactly<A>>();
  Expect.type<C>(a2);
  Expect.identical(a, a2);

  Future<void> f<X extends Object>(X x) async {
    var x2 = await x; // Remains an `A` and a `Future<Object?>`.
    x2.expectStaticType<Exactly<Object>>();
    Expect.type<Future<Object?>>(x2);
    Expect.identical(x, x2);
  }

  await f(Future<Object?>.value(null));

  Future<void> g<X extends A>(X x) async {
    var x2 = await x; // The future is awaited.
    x2.expectStaticType<Exactly<A>>();
    Expect.type<C1>(x2);
    Expect.notType<C2>(x2);
    Expect.notIdentical(x, x2);
  }

  await g(C2());
}
