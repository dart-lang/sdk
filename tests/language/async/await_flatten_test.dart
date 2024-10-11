// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:expect/static_type_helper.dart';

// Testing the behavior of flatten (cf. SDK issue #49396).

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

  // Type variable; called with `X == Object`.
  Future<void> f1<X extends Object>(X x) async {
    var x2 = await x; // Remains a `Future<Object?>`.
    x2.expectStaticType<Exactly<X>>();
    Expect.type<Future<Object?>>(x2);
    Expect.identical(x, x2);
  }

  await f1<Object>(Future<Object?>.value(null));

  // Type variable; called with `X == A`.
  Future<void> f2<X extends A>(X x) async {
    var x2 = await x; // The future is awaited.
    x2.expectStaticType<Exactly<X>>();
    Expect.type<C1>(x2);
    Expect.notType<C2>(x2);
    Expect.notIdentical(x, x2);
  }

  await f2<A>(C2());

  // Type variable; called with `X == C2`.
  Future<void> f3<X extends A>(X x) async {
    var x2 = await x; // Remains a `C2` and a `Future<C1>`.
    x2.expectStaticType<Exactly<X>>();
    Expect.type<C2>(x2);
    Expect.identical(x, x2);
  }

  await f3<C2>(C2());

  // Type variable; value of `X` makes no difference.
  Future<void> f4<X extends Future<A>>(X x) async {
    var x2 = await x; // The future is awaited.
    x2.expectStaticType<Exactly<A>>();
    Expect.type<C1>(x2);
    Expect.notType<C2>(x2);
    Expect.notIdentical(x, x2);
  }

  await f4<Future<A>>(C2());
  await f4<C2>(C2());

  // Type variable; value of `X` makes no difference.
  Future<void> f5<X extends FutureOr<A>>(X x) async {
    var x2 = await x; // The future is awaited.
    x2.expectStaticType<Exactly<A>>();
    Expect.type<C1>(x2);
    Expect.notType<C2>(x2);
    Expect.notIdentical(x, x2);
  }

  await f5<A>(C2());
  await f5<Future<A>>(C2());
  await f5<Future<C1>>(C2());
  await f5<C2>(C2());

  // Promoted type variable; called with `X == Object`.
  Future<void> g1<X>(X x) async {
    if (x is Object) {
      var x2 = await x; // Remains a `Future<Object?>`.
      x2.expectStaticType<Exactly<X>>();
      Expect.type<Future<Object?>>(x2);
      Expect.identical(x, x2);
    }
  }

  await g1<Object>(Future<Object?>.value(null));

  // Promoted type variable; called with `X == Object?`.
  Future<void> g2<X>(X x) async {
    if (x is Object) {
      var x2 = await x; // The future is awaited.
      x2.expectStaticType<Exactly<X>>();
      Expect.isNull(x2);
    }
  }

  await g2<Object?>(Future<Object?>.value(null));

  // Promoted type variable; called with `X == A`.
  Future<void> g3<X>(X x) async {
    if (x is A) {
      var x2 = await x; // The future is awaited.
      x2.expectStaticType<Exactly<X>>();
      Expect.type<C1>(x2);
      Expect.notType<C2>(x2);
      Expect.notIdentical(x, x2);
    }
  }

  await g3<A>(C2());

  // Promoted type variable; called with `X == C2`.
  Future<void> g4<X>(X x) async {
    if (x is A) {
      var x2 = await x; // Remains a `C2` and a `Future<C1>`.
      x2.expectStaticType<Exactly<X>>();
      Expect.type<C2>(x2);
      Expect.identical(x, x2);
    }
  }

  await g4<C2>(C2());

  // Promoted type variable; the value of `X` does not matter.
  Future<void> g5<X>(X x) async {
    if (x is Future<A>) {
      var x2 = await x; // The future is awaited.
      x2.expectStaticType<Exactly<A>>();
      Expect.type<C1>(x2);
      Expect.notType<C2>(x2);
      Expect.notIdentical(x, x2);
    }
  }

  await g5<A>(C2());
  await g5<C2>(C2());
  await g5<Future<A>>(C2());

  // Promoted type variable; the value of `X` does not matter.
  Future<void> g6<X>(X x) async {
    if (x is FutureOr<A>) {
      var x2 = await x; // The future is awaited.
      x2.expectStaticType<Exactly<A>>();
      Expect.type<C1>(x2);
      Expect.notType<C2>(x2);
      Expect.notIdentical(x, x2);
    }
  }

  await g6<A>(C2());
  await g6<C2>(C2());
  await g6<Future<A>>(C2());
  await g6<Future<C1>>(C2());

  // Promoted type variable; values of type variables makes no difference.
  Future<void> g7<X, Y extends Future<int>>(X x) async {
    if (x is Future<int> && x is Y) {
      // The promoted type of `x` is `X & Y`.
      var x2 = await x; // The future is awaited.
      x2.expectStaticType<Exactly<int>>();
      Expect.equals(1, x2);
    }
  }

  await g7<Object?, Future<int>>(Future<int>.value(1));

  // S? bounded type: called with `X == Null`.
  Future<void> h1<X extends Future<A>?>(X x) async {
    var x2 = await x; // Remains null.
    x2.expectStaticType<Exactly<A?>>();
    Expect.identical(null, x2);
  }

  await h1<Null>(null);

  // S? bounded type: called with `X == Future<A>`.
  Future<void> h2<X extends Future<A>?>(X x) async {
    var x2 = await x; // The future is awaited.
    x2.expectStaticType<Exactly<A?>>();
    Expect.type<C1>(x2);
    Expect.notType<C2>(x2);
    Expect.notIdentical(x, x2);
  }

  await h2<Future<A>>(C2());

  // S? bounded type: called with `X == Null`.
  Future<void> h3<X extends FutureOr<A>?>(X x) async {
    var x2 = await x; // Remains null.
    x2.expectStaticType<Exactly<A?>>();
    Expect.identical(null, x2);
  }

  await h3<Null>(null);

  // S? bounded type: called with `X == FutureOr<A>`.
  Future<void> h4<X extends FutureOr<A>?>(X x) async {
    var x2 = await x; // The future is awaited.
    x2.expectStaticType<Exactly<A?>>();
    Expect.type<C1>(x2);
    Expect.notType<C2>(x2);
    Expect.notIdentical(x, x2);
  }

  await h4<FutureOr<A>>(C2());
}
