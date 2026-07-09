// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the appropriate runtime checks occur when a generic class has a
// field (or getter) whose type is a callable class, and that type makes
// contravariant use of the generic class's type parameter.

import 'package:expect/expect.dart';

// The callable class. Contains machinery to verify that it is called only when
// expected.
class Callable<U> {
  static int _callCount = 0;
  dynamic call() {
    ++_callCount;
    return this;
  }

  static void checkCallCount(int expected) {
    Expect.equals(expected, _callCount);
    _callCount = 0;
  }
}

// A generic class containing fields whose type is a callable class.
class Fields<T> {
  final Callable<void Function()> noUse = Callable<void Function()>();
  final Callable<T Function()> covariantUse = Callable<T Function()>();
  final Callable<void Function(T)> contravariantUse =
      Callable<void Function(T)>();
  final Callable<T Function(T)> invariantUse = Callable<T Function(T)>();
}

// A generic class containing getters whose type is a callable class.
class Getters<T> {
  final Fields<T> _fields = Fields<T>();

  Callable<void Function()> get noUse => _fields.noUse;
  Callable<T Function()> get covariantUse => _fields.covariantUse;
  Callable<void Function(T)> get contravariantUse => _fields.contravariantUse;
  Callable<T Function(T)> get invariantUse => _fields.invariantUse;
}

void testFields(Fields<num> fields, {required bool expectException}) {
  // Make a copy of the `fields` parameter with type `dynamic`, so that we can
  // access its fields without triggering runtime covariance checks; we'll use
  // this to determine the values that are expected to be returned by
  // `Callable.call`.
  dynamic d = fields;

  // `fields.noUse` doesn't use the type parameter `T`, so no runtime check is
  // needed to preserve soundness.
  Expect.identical(d.noUse, fields.noUse());
  Callable.checkCallCount(1);

  // `fields.covariantUse` uses the type parameter `T` covariantly, so no
  // runtime check is needed to preserve soundness.
  Expect.identical(d.covariantUse, fields.covariantUse());
  Callable.checkCallCount(1);

  // `fields.contravariantUse` uses the type parameter `T` contravariantly, so a
  // runtime check is needed to preserve soundness.
  if (expectException) {
    Expect.throws(() => fields.contravariantUse());
    Callable.checkCallCount(0);
  } else {
    Expect.identical(d.contravariantUse, fields.contravariantUse());
    Callable.checkCallCount(1);
  }

  // `fields.invariantUse` uses the type parameter `T` both covariantly and
  // contravariantly, so a runtime check is needed to preserve soundness.
  if (expectException) {
    Expect.throws(() => fields.invariantUse());
    Callable.checkCallCount(0);
  } else {
    Expect.identical(d.invariantUse, fields.invariantUse());
    Callable.checkCallCount(1);
  }
}

void testGetters(Getters<num> getters, {required bool expectException}) {
  // Make a copy of the `getters` parameter with type `dynamic`, so that we can
  // access its getters without triggering runtime covariance checks; we'll use
  // this to determine the values that are expected to be returned by
  // `Callable.call`.
  dynamic d = getters;

  // `getters.noUse` doesn't use the type parameter `T`, so no runtime check is
  // needed to preserve soundness.
  Expect.identical(d.noUse, getters.noUse());
  Callable.checkCallCount(1);

  // `getters.covariantUse` uses the type parameter `T` covariantly, so no
  // runtime check is needed to preserve soundness.
  Expect.identical(d.covariantUse, getters.covariantUse());
  Callable.checkCallCount(1);

  // `getters.contravariantUse` uses the type parameter `T` contravariantly, so
  // a runtime check is needed to preserve soundness.
  if (expectException) {
    Expect.throws(() => getters.contravariantUse());
    Callable.checkCallCount(0);
  } else {
    Expect.identical(d.contravariantUse, getters.contravariantUse());
    Callable.checkCallCount(1);
  }

  // `getters.invariantUse` uses the type parameter `T` both covariantly and
  // contravariantly, so a runtime check is needed to preserve soundness.
  if (expectException) {
    Expect.throws(() => getters.invariantUse());
    Callable.checkCallCount(0);
  } else {
    Expect.identical(d.invariantUse, getters.invariantUse());
    Callable.checkCallCount(1);
  }
}

main() {
  testFields(Fields<num>(), expectException: false);
  testFields(Fields<int>(), expectException: true);
  testGetters(Getters<num>(), expectException: false);
  testGetters(Getters<int>(), expectException: true);
}
