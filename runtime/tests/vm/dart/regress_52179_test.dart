// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that VM doesn't crash when taking a constructor tear-off
// with nested function types.
// Regression test for https://github.com/dart-lang/sdk/issues/52179.

import 'package:expect/expect.dart';

class A<E> {
  factory A(
      {bool Function(E, E)? a1,
      int Function(E)? a2,
      bool Function(dynamic)? a3}) {
    return A<E>._();
  }

  A._();
}

main() {
  dynamic x = A.new;
  dynamic y = A<String>.new;
  Expect.isTrue(x is A<T> Function<T>(
      {bool Function(T, T)? a1,
      int Function(T)? a2,
      bool Function(dynamic)? a3}));
  Expect.isTrue(y is A<String> Function(
      {bool Function(String, String)? a1,
      int Function(String)? a2,
      bool Function(dynamic)? a3}));
  Expect.isTrue(x() is A<dynamic>);
  Expect.isTrue(x<int>() is A<int>);
  Expect.isTrue(x(a3: (_) => true) is A<dynamic>);
  Expect.isTrue(x<double>(a2: (double _) => 42) is A<double>);
  Expect.isTrue(y() is A<String>);
}
