// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We say that a type T derives a future type F in the following cases,
// using the first applicable case:
//
// 1. If T is a type which is introduced by a class, mixin, or enum
//    declaration, and if T or a direct or indirect superinterface of T
//    is Future<U> for some U, then T derives the future type Future<U>.
// 2. If T is the type FutureOr<U> for some U, then T derives the future
//    type FutureOr<U>.
// 3. If T is S? for some S, and S derives the future type F, then T derives
//    the future type F?.
// 4. If T is a type variable with bound B, and B derives the future type F,
//    then T derives the future type F.
// -  (There is no rule for the case where T is of the form X&S because this
//    will never occur.)
//
// In Dart of today, rule 1 is extended with a case for extension types.
//
// Many test cases below use an expression of the form `await e` where the
// static type of `e` is such that the rule in the definition of _flatten_
// which is used is one of the following:
//
// - If T derives a future type Future<S> or FutureOr<S> then flatten(T) = S.
// - If T derives a future type Future<S>? or FutureOr<S>? then flatten(T) = S?.
//
// This implies that the test which is concerned with the behavior of _flatten_
// is pretty directly also a test of the behavior of "derives a future type".
//
// To see that the "derives a future type" algorithm is applied correctly,
// we also need to check types of the form `X & B`, for which the "derives a
// future type" algorithm is applied to `B`. This kind of test is also needed
// for one more reason: If an implementation is not updated at all (so it
// uses the old definition of _flatten_) then it would succeed in many `T?`
// tests without ever invoking the "derives a future type" algorithm at all.
// With a type of the form `X & B`, both the old and the new definition must
// use "derives a future type".
//
// Comments of the form '// 3.2 ...' are used to indicate which rules are
// usde to find the future type which is derived: Rule 3 is used first, then
// a recursive invocation uses rule 2, and similarly for other digit
// sequences.

import 'dart:async';
import 'package:expect/static_type_helper.dart';

mixin class FakeFutureHelper<T> {
  Future<T> get _realFuture;
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) =>
      _realFuture.then<R>(onValue, onError: onError);
  Future<T> catchError(Function onError, {bool Function(Object)? test}) =>
      _realFuture.catchError(onError, test: test);
  Future<T> whenComplete(FutureOr<void> Function() onDone) =>
      _realFuture.whenComplete(onDone);
  noSuchMethod(i) => throw UnimplementedError("Not needed for test");
}

class SubFuture extends FakeFutureHelper<int> implements Future<int> {
  final Future<int> _realFuture = Future<int>.value(0);
}

mixin MixFuture implements Future<int> {
  final Future<int> _realFuture = Future<int>.value(0);
}

class WithMixFuture extends Object with FakeFutureHelper<int>, MixFuture {
  final Future<int> _realFuture = Future<int>.value(0);
}

enum EnumFuture with FakeFutureHelper<int> implements Future<int> {
  one,
  two;

  Future<int> get _realFuture => this == one ? _futureOne : _futureTwo;

  static final Future<int> _futureOne = Future<int>.value(1);
  static final Future<int> _futureTwo = Future<int>.value(2);
}

// Note that the representation type is different from the superinterface.
extension type ExtensionFuture(Future<String> _) implements Future<String?> {}

extension type ExtensionSubFuture(SubFuture _) implements SubFuture {}

void main() async {
  {
    // 1, derives `Future<String>`.
    var x = Future<String>.value("Whatever");
    (await x).expectStaticType<Exactly<String>>();
  }
  {
    // 1, derives `Future<int>`.
    var x = SubFuture();
    (await x).expectStaticType<Exactly<int>>();
  }
  {
    // 1, derives `Future<int>`.
    MixFuture x = WithMixFuture();
    (await x).expectStaticType<Exactly<int>>();
  }
  {
    // 1, derives `Future<int>`.
    var x = EnumFuture.one;
    (await x).expectStaticType<Exactly<int>>();
  }
  {
    // 1, derives `Future<String?>`.
    var x = ExtensionFuture(Future<String>.value("Whatever"));
    (await x).expectStaticType<Exactly<String?>>();
  }
  {
    // 1, derives `Future<int>`.
    var x = ExtensionSubFuture(SubFuture());
    (await x).expectStaticType<Exactly<int>>();
  }
  {
    // 2, derives `FutureOr<bool>`.
    FutureOr<bool> x = true;
    (await x).expectStaticType<Exactly<bool>>();
  }
  {
    // 2, derives `FutureOr<bool?>`.
    FutureOr<bool?> x = true;
    (await x).expectStaticType<Exactly<bool?>>();
  }
  {
    // 3.1, derives `Future<String>?`.
    Future<String>? x;
    (await x).expectStaticType<Exactly<String?>>();
  }
  {
    // 3.1, derives `Future<int>?`.
    SubFuture? x;
    (await x).expectStaticType<Exactly<int?>>();
  }
  {
    // 3.1, derives `Future<int>?`.
    MixFuture? x;
    (await x).expectStaticType<Exactly<int?>>();
  }
  {
    // 3.1, derives `Future<int>?`.
    EnumFuture? x;
    (await x).expectStaticType<Exactly<int?>>();
  }
  {
    // 3.1, derives `Future<String?>?`.
    ExtensionFuture? x;
    (await x).expectStaticType<Exactly<String?>>();
  }
  {
    // 3.1, derives `Future<int>?`.
    ExtensionSubFuture? x;
    (await x).expectStaticType<Exactly<int?>>();
  }
  {
    // 3.2, derives `FutureOr<bool>?`.
    FutureOr<bool>? x;
    (await x).expectStaticType<Exactly<bool?>>();
  }
  {
    // 3.2, derives `FutureOr<bool?>?`.
    FutureOr<bool?>? x;
    (await x).expectStaticType<Exactly<bool?>>();
  }

  await f1<Future<int>, SubFuture, ExtensionFuture, ExtensionSubFuture,
          FutureOr<Object>, Future<Never>?, Future<Symbol>, Future<Symbol>>(
      Future<int>.value(10),
      SubFuture(),
      ExtensionFuture(Future<String>.value('f1')),
      ExtensionSubFuture(SubFuture()),
      20,
      null,
      Future.value(#foo));

  await f2<Object?, Future<Never>, FutureOr<Object>, Future<Never>?,
      Future<Symbol>, Future<Symbol>>(true);

  await C1<Future<int>, SubFuture, ExtensionFuture, ExtensionSubFuture,
          FutureOr<Object>, Future<Never>?, Future<Symbol>, Future<Symbol>>()
      .f1(
          Future<int>.value(10),
          SubFuture(),
          ExtensionFuture(Future<String>.value('f1')),
          ExtensionSubFuture(SubFuture()),
          20,
          null,
          Future.value(#foo));

  await C2<Object?, Future<Never>, FutureOr<Object>, Future<Never>?,
          Future<Symbol>, Future<Symbol>>()
      .f2(true);
}

// Test non-promoted types that involve function type parameters.
Future<void> f1<
        X1a extends Future<int>,
        X1b extends SubFuture,
        X1c extends ExtensionFuture,
        X1d extends ExtensionSubFuture,
        X2 extends FutureOr<Object>,
        X3 extends Future<Never>?,
        X4 extends Y,
        Y extends Future<Symbol>>(
    X1a x1a, X1b x1b, X1c x1c, X1d x1d, X2 x2, X3 x3, X4 x4) async {
  // 4.1, `X1a` derives `Future<int>`.
  (await x1a).expectStaticType<Exactly<int>>();

  // 4.1, `X1b` derives `Future<int>`.
  (await x1b).expectStaticType<Exactly<int>>();

  // 4.1, `X1c` derives `Future<String?>`.
  (await x1c).expectStaticType<Exactly<String?>>();

  // 4.1, `X1d` derives `Future<int>`.
  (await x1d).expectStaticType<Exactly<int>>();

  // 4.2, `X2` derives `FutureOr<Object>`.
  (await x2).expectStaticType<Exactly<Object>>();

  // 4.3.1, `X3` derives `Future<Never>?`.
  (await x3).expectStaticType<Exactly<Never?>>();

  // 4.4.1, `X4` derives `Future<Symbol>`.
  (await x4).expectStaticType<Exactly<Symbol>>();

  {
    // 3.4.1, `X1a?` derives `Future<int>?`.
    X1a? x;
    (await x).expectStaticType<Exactly<int?>>();
  }
  {
    // 3.4.1, `X1b?` derives `Future<int>?`.
    X1b? x;
    (await x).expectStaticType<Exactly<int?>>();
  }
  {
    // 3.4.1, `X1c?` derives `Future<String?>?`.
    X1c? x;
    (await x).expectStaticType<Exactly<String?>>();
  }
  {
    // 3.4.1, `X1d?` derives `Future<int>?`.
    X1d? x;
    (await x).expectStaticType<Exactly<int?>>();
  }
  {
    // 3.4.2, `X2?` derives `FutureOr<Object>?`.
    X2? x;
    (await x).expectStaticType<Exactly<Object?>>();
  }
  {
    // 3.4.3.1, `X3?` derives `Future<Never>??`, i.e., `Future<Never>?`.
    X3? x;
    (await x).expectStaticType<Exactly<Never?>>();
  }
  {
    // 3.4.4.1, `X4?` derives `Future<Symbol>?`.
    X4? x;
    (await x).expectStaticType<Exactly<Symbol?>>();
  }
}

// Test promoted types that involve function type parameters. In this
// case the type of `x` is of the form `X & B`, which calls for the
// future type that `B` derives (if any). So the type of `x` may be
// `X & X1?`, but the relevant question is then: which future type does
// `X1?` derive?
Future<void> f2<
    X,
    X1 extends Future<Never>,
    X2 extends FutureOr<Object>,
    X3 extends Future<Never>?,
    X4 extends Y,
    Y extends Future<Symbol>>(X x) async {
  if (x is X1) {
    // 4.1, `X1` derives `Future<Never>`.
    (await x).expectStaticType<Exactly<Never?>>();
  }

  if (x is X2) {
    // 4.2, `X2` derives `FutureOr<Object>`.
    (await x).expectStaticType<Exactly<Object>>();
  }

  if (x is X3) {
    // 4.3.1, `X3` derives `Future<Never>?`.
    (await x).expectStaticType<Exactly<Never?>>();
  }

  if (x is X4) {
    // 4.4.1, `X4` derives `Future<Symbol>`.
    (await x).expectStaticType<Exactly<Symbol>>();
  }

  if (x is X1?) {
    // 3.4.1, `X1?` derives `Future<Never>?`.
    (await x).expectStaticType<Exactly<Never?>>();
  }

  if (x is X2?) {
    // 3.4.2, `X2?` derives `FutureOr<Object>?`.
    (await x).expectStaticType<Exactly<Object?>>();
  }

  if (x is X3?) {
    // 3.4.3.1, `X3?` derives `Future<Never>??`, i.e., `Future<Never>?`.
    X3? x;
    (await x).expectStaticType<Exactly<Never?>>();
  }

  if (x is X4?) {
    // 3.4.4.1, `X4?` derives `Future<Symbol>?`.
    (await x).expectStaticType<Exactly<Symbol?>>();
  }
}

// Test non-promoted types that involve class type parameters.
class C1<
    X1a extends Future<int>,
    X1b extends SubFuture,
    X1c extends ExtensionFuture,
    X1d extends ExtensionSubFuture,
    X2 extends FutureOr<Object>,
    X3 extends Future<Never>?,
    X4 extends Y,
    Y extends Future<Symbol>> {
  Future<void> f1(
      X1a x1a, X1b x1b, X1c x1c, X1d x1d, X2 x2, X3 x3, X4 x4) async {
    // 4.1, `X1a` derives `Future<int>`.
    (await x1a).expectStaticType<Exactly<int>>();

    // 4.1, `X1b` derives `Future<int>`.
    (await x1b).expectStaticType<Exactly<int>>();

    // 4.1, `X1c` derives `Future<String?>`.
    (await x1c).expectStaticType<Exactly<String?>>();

    // 4.1, `X1d` derives `Future<int>`.
    (await x1d).expectStaticType<Exactly<int>>();

    // 4.2, `X2` derives `FutureOr<Object>`.
    (await x2).expectStaticType<Exactly<Object>>();

    // 4.3.1, `X3` derives `Future<Never>?`.
    (await x3).expectStaticType<Exactly<Never?>>();

    // 4.4.1, `X4` derives `Future<Symbol>`.
    (await x4).expectStaticType<Exactly<Symbol>>();

    {
      // 3.4.1, `X1a?` derives `Future<int>?`.
      X1a? x;
      (await x).expectStaticType<Exactly<int?>>();
    }
    {
      // 3.4.1, `X1b?` derives `Future<int>?`.
      X1b? x;
      (await x).expectStaticType<Exactly<int?>>();
    }
    {
      // 3.4.1, `X1c?` derives `Future<String?>?`.
      X1c? x;
      (await x).expectStaticType<Exactly<String?>>();
    }
    {
      // 3.4.1, `X1d?` derives `Future<int>?`.
      X1d? x;
      (await x).expectStaticType<Exactly<int?>>();
    }
    {
      // 3.4.2, `X2?` derives `FutureOr<Object>?`.
      X2? x;
      (await x).expectStaticType<Exactly<Object?>>();
    }
    {
      // 3.4.3.1, `X3?` derives `Future<Never>??`, i.e., `Future<Never>?`.
      X3? x;
      (await x).expectStaticType<Exactly<Never?>>();
    }
    {
      // 3.4.4.1, `X4?` derives `Future<Symbol>?`.
      X4? x;
      (await x).expectStaticType<Exactly<Symbol?>>();
    }
  }
}

// Test promoted types that involve type parameters. In this case the
// type of `x` is of the form `X & B`, which calls for the future type
// that `B` derives (if any). So the type of `x` may be `X & X1?`, but
// the relevant question is then: which future type does `X1?` derive?
class C2<X, X1 extends Future<Never>, X2 extends FutureOr<Object>,
    X3 extends Future<Never>?, X4 extends Y, Y extends Future<Symbol>> {
  Future<void> f2(X x) async {
    if (x is X1) {
      // 4.1, `X1` derives `Future<Never>`.
      (await x).expectStaticType<Exactly<Never?>>();
    }

    if (x is X2) {
      // 4.2, `X2` derives `FutureOr<Object>`.
      (await x).expectStaticType<Exactly<Object>>();
    }

    if (x is X3) {
      // 4.3.1, `X3` derives `Future<Never>?`.
      (await x).expectStaticType<Exactly<Never?>>();
    }

    if (x is X4) {
      // 4.4.1, `X4` derives `Future<Symbol>`.
      (await x).expectStaticType<Exactly<Symbol>>();
    }

    if (x is X1?) {
      // 3.4.1, `X1?` derives `Future<Never>?`.
      (await x).expectStaticType<Exactly<Never?>>();
    }

    if (x is X2?) {
      // 3.4.2, `X2?` derives `FutureOr<Object>?`.
      (await x).expectStaticType<Exactly<Object?>>();
    }

    if (x is X3?) {
      // 3.4.3.1, `X3?` derives `Future<Never>??`, i.e., `Future<Never>?`.
      X3? x;
      (await x).expectStaticType<Exactly<Never?>>();
    }

    if (x is X4?) {
      // 3.4.4.1, `X4?` derives `Future<Symbol>?`.
      (await x).expectStaticType<Exactly<Symbol?>>();
    }
  }
}
