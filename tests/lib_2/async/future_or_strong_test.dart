// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In strong mode, `FutureOr` should be equivalent to the union of `Future<T>`
// and `T`.

import 'dart:async';
import 'package:expect/expect.dart';

typedef void FunTakes<T>(T x);
typedef T FunReturns<T>();

main() {
  Expect.isTrue(499 is FutureOr); // Same as `is Object`.
  Expect.isTrue(499 is FutureOr<int>);
  Expect.isFalse(499 is FutureOr<String>);

  Expect.isTrue(new Future.value(499) is FutureOr); // Same as `is Object`.
  Expect.isTrue(new Future.value(499) is FutureOr<int>);
  Expect.isFalse(new Future.value(499) is FutureOr<String>);

  void foo(FutureOr x) {} // Equivalent to `void bar(Object x) {}`.

  // A function that takes Object takes everything.
  Expect.isTrue(foo is FunTakes<dynamic>);
  Expect.isTrue(foo is FunTakes<Object>);
  Expect.isTrue(foo is FunTakes<int>);
  Expect.isTrue(foo is FunTakes<String>);
  Expect.isTrue(foo is FunTakes<Future<int>>);
  Expect.isTrue(foo is FunTakes<Future<String>>);
  Expect.isTrue(foo is FunTakes<FutureOr<Object>>);
  Expect.isTrue(foo is FunTakes<FutureOr<int>>);
  Expect.isTrue(foo is FunTakes<FutureOr<String>>);
  Expect.isTrue(foo is FunTakes<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(foo is FunTakes<FutureOr<FutureOr<int>>>);
  Expect.isTrue(foo is FunTakes<FutureOr<FutureOr<String>>>);

  FutureOr bar() => 499; // Equivalent to `Object foo() => 499`.

  Expect.isTrue(bar is FunReturns<dynamic>);
  Expect.isTrue(bar is FunReturns<Object>);
  Expect.isFalse(bar is FunReturns<int>);
  Expect.isFalse(bar is FunReturns<String>);
  Expect.isFalse(bar is FunReturns<Future<int>>);
  Expect.isFalse(bar is FunReturns<Future<String>>);
  Expect.isTrue(bar is FunReturns<FutureOr<Object>>);
  Expect.isFalse(bar is FunReturns<FutureOr<int>>);
  Expect.isFalse(bar is FunReturns<FutureOr<String>>);
  Expect.isTrue(bar is FunReturns<FutureOr<FutureOr<Object>>>);
  Expect.isFalse(bar is FunReturns<FutureOr<FutureOr<int>>>);
  Expect.isFalse(bar is FunReturns<FutureOr<FutureOr<String>>>);

  void foo2(FutureOr<String> x) {}

  // In is-checks `dynamic` is treat specially (counting as bottom in parameter
  // positions).
  Expect.isTrue(foo2 is FunTakes<dynamic>);

  Expect.isFalse(foo2 is FunTakes<Object>);
  Expect.isFalse(foo2 is FunTakes<int>);
  Expect.isTrue(foo2 is FunTakes<String>);
  Expect.isFalse(foo2 is FunTakes<Future<int>>);
  Expect.isTrue(foo2 is FunTakes<Future<String>>);
  Expect.isFalse(foo2 is FunTakes<FutureOr<Object>>);
  Expect.isFalse(foo2 is FunTakes<FutureOr<int>>);
  Expect.isTrue(foo2 is FunTakes<FutureOr<String>>);
  Expect.isFalse(foo2 is FunTakes<FutureOr<FutureOr<Object>>>);
  Expect.isFalse(foo2 is FunTakes<FutureOr<FutureOr<int>>>);
  Expect.isFalse(foo2 is FunTakes<FutureOr<FutureOr<String>>>);

  FutureOr<int> bar2() => 499;

  Expect.isTrue(bar2 is FunReturns<dynamic>);
  Expect.isTrue(bar2 is FunReturns<Object>);
  Expect.isFalse(bar2 is FunReturns<int>);
  Expect.isFalse(bar2 is FunReturns<String>);
  Expect.isFalse(bar2 is FunReturns<Future<int>>);
  Expect.isFalse(bar2 is FunReturns<Future<String>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<Object>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<int>>);
  Expect.isFalse(bar2 is FunReturns<FutureOr<String>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<FutureOr<int>>>);
  Expect.isFalse(bar2 is FunReturns<FutureOr<FutureOr<String>>>);

  void foo3(String x) {}

  // In is-checks `dynamic` is treat specially (counting as bottom in parameter
  // positions).
  Expect.isTrue(foo3 is FunTakes<dynamic>);

  Expect.isFalse(foo3 is FunTakes<Object>);
  Expect.isFalse(foo3 is FunTakes<int>);
  Expect.isTrue(foo3 is FunTakes<String>);
  Expect.isFalse(foo3 is FunTakes<Future<int>>);
  Expect.isFalse(foo3 is FunTakes<Future<String>>);
  Expect.isFalse(foo3 is FunTakes<FutureOr<Object>>);
  Expect.isFalse(foo3 is FunTakes<FutureOr<int>>);
  Expect.isFalse(foo3 is FunTakes<FutureOr<String>>);
  Expect.isFalse(foo3 is FunTakes<FutureOr<FutureOr<Object>>>);
  Expect.isFalse(foo3 is FunTakes<FutureOr<FutureOr<int>>>);
  Expect.isFalse(foo3 is FunTakes<FutureOr<FutureOr<String>>>);

  int bar3() => 499;

  Expect.isTrue(bar3 is FunReturns<dynamic>);
  Expect.isTrue(bar3 is FunReturns<Object>);
  Expect.isTrue(bar3 is FunReturns<int>);
  Expect.isFalse(bar3 is FunReturns<String>);
  Expect.isFalse(bar3 is FunReturns<Future<int>>);
  Expect.isFalse(bar3 is FunReturns<Future<String>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<Object>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<int>>);
  Expect.isFalse(bar3 is FunReturns<FutureOr<String>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<FutureOr<int>>>);
  Expect.isFalse(bar3 is FunReturns<FutureOr<FutureOr<String>>>);
}
