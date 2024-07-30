// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that the `flatten` function is implemented and applied correctly
// when applied to interfaces that have `Future` as a superinterface.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import '../static_type_helper.dart';

mixin Base {
  noSuchMethod(Invocation invocation) {
    if (const {
      #then,
      #catchError,
      #whenComplete,
    }.contains(invocation.memberName)) {
      // Throw a sentinel value (using the receiver since it's available)
      // when one of the `Future` callback methods is called.
      throw this;
    }
    return super.noSuchMethod(invocation);
  }
}

extension on Future<void> {
  Future<void> ignoreError<T>() => then((_) => null, onError: (e) {
        if (e is! T) throw e;
      });
}

class Derived<T> = Object with Base implements Future<T>;

class FixedPoint<T> = Object with Base implements Future<FixedPoint<T>>;

class Divergent<T> = Object
    with Base
    implements Future<Divergent<Divergent<T>>>;

void main() async {
  asyncStart();
  // ----- Test the static types of await on the non-standard futures.

  bool obscureFalse = DateTime.now().millisecondsSinceEpoch < 0;

  if (obscureFalse) {
    var x1 = await Derived<int>();
    x1.expectStaticType<Exactly<int>>();

    var x2 = await FixedPoint<int>();
    x2.expectStaticType<Exactly<FixedPoint<int>>>();

    var x3 = await Divergent<int>();
    x3.expectStaticType<Exactly<Divergent<Divergent<int>>>>();
  }

  // ----- flatten(Derived<int>) == int.

  try {
    int x = await Derived<int>();
    Expect.fail("Derived did not throw");
  } on Derived {
    // Expected throw.
  }

  Future<int> f1() async => Derived<int>();

  // A non-standard future which implements `Future<int>` can be returned
  // in an async function with return type `Future<int>`. It does not
  // implement any members, so we need to ignore the dynamic error that
  // occurs when any of its future callback methods is called.
  f1().ignoreError<Derived>();

  Future<int> f2() async {
    return Derived<int>();
  }

  // Like the `f1` case, using a `{}` function.
  f2().ignoreError<Derived>();

  Future<int> x1 = (() async => Derived<int>())();

  try {
    await x1;
    Expect.fail("Derived did not throw");
  } on Derived {
    // Expected throw.
  }

  // ----- flatten(FixedPoint<int>) == FixedPoint<int>.

  try {
    FixedPoint<int> x = await FixedPoint<int>();
    Expect.fail("FixedPoint did not throw");
  } on FixedPoint {
    // Expected throw.
  }

  Future<FixedPoint<int>> f3() async => FixedPoint<int>();

  f3().ignoreError<FixedPoint>();

  Future<FixedPoint<int>> f4() async {
    return FixedPoint<int>();
  }

  f4().ignoreError<FixedPoint>();

  Future<FixedPoint<int>> x2 = (() async => FixedPoint<int>())();

  try {
    await x2;
    Expect.fail("FixedPoint did not throw");
  } on FixedPoint {
    // Expected throw.
  }

  // ----- flatten(Divergent<int>) == Divergent<Divergent<int>>.

  try {
    Divergent<Divergent<int>> x = await Divergent<int>();
    Expect.fail("Divergent did not throw");
  } on Divergent {
    // Expected throw.
  }

  Future<Divergent<Divergent<int>>> f5() async => Divergent<int>();
  f5().ignoreError<Divergent>();

  Future<Divergent<Divergent<int>>> f6() async {
    return Divergent<int>();
  }

  f6().ignoreError<Divergent>();

  Future<Divergent<Divergent<int>>> f7() async => Divergent<int>();
  Future<Divergent<Divergent<int>>> x3 = f7();

  try {
    await x3;
    Expect.fail("Divergent did not throw");
  } on Divergent {
    // Expected throw.
  }
  asyncEnd();
}
