// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test that checks that if we rename symbols based on the
// order we see them in the source code, but don't properly sort them based on
// the new order in function types, the runtime type checker generates
// incorrect results.

// dart2wasmOptions=--minify

import 'package:expect/expect.dart';

bool get runtimeTrue => int.parse('1') == 1;

void main() {
  // Process symbols "a" and "b" in different orders to test different orderings
  // between the function named parameter symbols.
  print(const Symbol("a")); //# 01: ok
  print(const Symbol("b")); //# 01: continued

  print(const Symbol("b")); //# 02: ok
  print(const Symbol("a")); //# 02: continued

  // `runtimeTrue` to avoid TFA from optimizing the type check code.
  Expect.isTrue(
    (runtimeTrue ? (({int? a, int? b}) {}) : () {}) is Function({int? b}),
  );
  Expect.isFalse((runtimeTrue ? (({int? a}) {}) : () {}) is Function({int? b}));

  // Same as above, but with runtime-generated function types.
  void f<T1, T2>() {
    Expect.isTrue(
      (runtimeTrue ? (({T1? a, T2? b}) {}) : (() {})) is Function({T2? b}),
    );
    Expect.isFalse(
      (runtimeTrue ? (({T1? a}) {}) : (() {})) is Function({T2? b}),
    );
  }

  f<int?, int?>();
  f<bool?, int?>();
}
