// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In non strong-mode, `FutureOr` should just behave like dynamic.

import 'dart:async';
import 'package:expect/expect.dart';

typedef void FunTakes<T>(T x);
typedef T FunReturns<T>();

main() {
  Expect.isTrue(499 is FutureOr);
  Expect.isTrue(499 is FutureOr<String>);
  Expect.isTrue(499 is FutureOr<int>);

  Expect.isTrue(new Future.value(499) is FutureOr);
  Expect.isTrue(new Future.value(499) is FutureOr<int>);
  Expect.isTrue(new Future.value(499) is FutureOr<String>);

  void foo(FutureOr x) {}

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

  FutureOr bar() => 499;

  Expect.isTrue(bar is FunReturns<dynamic>);
  Expect.isTrue(bar is FunReturns<Object>);
  Expect.isTrue(bar is FunReturns<int>);
  Expect.isTrue(bar is FunReturns<String>);
  Expect.isTrue(bar is FunReturns<Future<int>>);
  Expect.isTrue(bar is FunReturns<Future<String>>);
  Expect.isTrue(bar is FunReturns<FutureOr<Object>>);
  Expect.isTrue(bar is FunReturns<FutureOr<int>>);
  Expect.isTrue(bar is FunReturns<FutureOr<String>>);
  Expect.isTrue(bar is FunReturns<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(bar is FunReturns<FutureOr<FutureOr<int>>>);
  Expect.isTrue(bar is FunReturns<FutureOr<FutureOr<String>>>);

  void foo2(FutureOr<String> x) {}

  Expect.isTrue(foo2 is FunTakes<dynamic>);
  Expect.isTrue(foo2 is FunTakes<Object>);
  Expect.isTrue(foo2 is FunTakes<int>);
  Expect.isTrue(foo2 is FunTakes<String>);
  Expect.isTrue(foo2 is FunTakes<Future<int>>);
  Expect.isTrue(foo2 is FunTakes<Future<String>>);
  Expect.isTrue(foo2 is FunTakes<FutureOr<Object>>);
  Expect.isTrue(foo2 is FunTakes<FutureOr<int>>);
  Expect.isTrue(foo2 is FunTakes<FutureOr<String>>);
  Expect.isTrue(foo2 is FunTakes<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(foo2 is FunTakes<FutureOr<FutureOr<int>>>);
  Expect.isTrue(foo2 is FunTakes<FutureOr<FutureOr<String>>>);

  FutureOr<int> bar2() => 499;

  Expect.isTrue(bar2 is FunReturns<dynamic>);
  Expect.isTrue(bar2 is FunReturns<Object>);
  Expect.isTrue(bar2 is FunReturns<int>);
  Expect.isTrue(bar2 is FunReturns<String>);
  Expect.isTrue(bar2 is FunReturns<Future<int>>);
  Expect.isTrue(bar2 is FunReturns<Future<String>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<Object>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<int>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<String>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<FutureOr<int>>>);
  Expect.isTrue(bar2 is FunReturns<FutureOr<FutureOr<String>>>);

  void foo3(String x) {}

  Expect.isTrue(foo3 is FunTakes<dynamic>);
  Expect.isTrue(foo3 is FunTakes<Object>);
  Expect.isFalse(foo3 is FunTakes<int>);
  Expect.isTrue(foo3 is FunTakes<String>);
  Expect.isFalse(foo3 is FunTakes<Future<int>>);
  Expect.isFalse(foo3 is FunTakes<Future<String>>);
  Expect.isTrue(foo3 is FunTakes<FutureOr<Object>>);
  Expect.isTrue(foo3 is FunTakes<FutureOr<int>>);
  Expect.isTrue(foo3 is FunTakes<FutureOr<String>>);
  Expect.isTrue(foo3 is FunTakes<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(foo3 is FunTakes<FutureOr<FutureOr<int>>>);
  Expect.isTrue(foo3 is FunTakes<FutureOr<FutureOr<String>>>);

  int bar3() => 499;

  Expect.isTrue(bar3 is FunReturns<dynamic>);
  Expect.isTrue(bar3 is FunReturns<Object>);
  Expect.isTrue(bar3 is FunReturns<int>);
  Expect.isFalse(bar3 is FunReturns<String>);
  Expect.isFalse(bar3 is FunReturns<Future<int>>);
  Expect.isFalse(bar3 is FunReturns<Future<String>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<Object>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<int>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<String>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<FutureOr<Object>>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<FutureOr<int>>>);
  Expect.isTrue(bar3 is FunReturns<FutureOr<FutureOr<String>>>);
}
