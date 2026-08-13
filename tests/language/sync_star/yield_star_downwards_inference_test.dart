// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import '../static_type_helper.dart';

class A with IterableMixin<dynamic> {
  /// This do-nothing method is only defined for the class `A`, so calling it
  /// serves as a runtime check that `this` is `A`.
  void checkThisIsA() {}

  @override
  get iterator => [].iterator;
}

dynamic returnTypeIsDynamic() sync* {
  T f<T>() => A() as T;

  // Downward inference context for the operand of `yield*` is `_`, so `f` is
  // instantiated as `f<dynamic>`, hence the call to `..checkThisIsA()` is
  // allowed (it's a dynamic invocation).
  yield* f()..checkThisIsA();
}

Iterable<dynamic> returnTypeIsIterableDynamic() sync* {
  // Downward inference context for the operand of `yield*` is
  // `Iterable<dynamic>`.
  yield* contextType(A())..expectStaticType<Exactly<Iterable<dynamic>>>();
}

dynamic returnContextIsUnknown() {
  T f<T>() => A() as T;

  var g = () sync* {
    // Downward inference context for the operand of `yield*` is `_`, so `f` is
    // instantiated as `f<dynamic>`, hence the call to `..checkThisIsA()` is
    // allowed (it's a dynamic invocation).
    yield* f()..checkThisIsA();
  };
  return g();
}

dynamic returnContextIsIterableUnknown() {
  T f<T>(Iterable<T> Function() g) => g() as T;
  T h<T>() => A() as T;

  var x = f(
    // Context for `f(...)` is `_`, so context for this closure is
    // `Iterable<_> Function()`.
    () sync* {
      // Downward inference context for the operand of `yield*` is `_`, so `h`
      // is instantiated as `h<dynamic>`, hence the call to `..checkThisIsA()`
      // is allowed (it's a dynamic invocation).
      yield* h()..checkThisIsA();
    },
  );

  // f() returns the yielded iterable, so just return x.
  return x;
}

main() {
  for (var _ in returnTypeIsDynamic()) {}
  for (var _ in returnTypeIsIterableDynamic()) {}
  for (var _ in returnContextIsUnknown()) {}
  for (var _ in returnContextIsIterableUnknown()) {}
}
