// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--minify

import 'package:expect/expect.dart';

void f({int a = 0}) {
  Expect.equals(123, a);
}

bool get runtimeTrue => int.parse('1') == 1;

void main() {
  // With minification, non-const symbols won't be identical or equal to the
  // const symbols, so `Symbol('a')` here won't match `a` in the `f`'s named
  // parameters and `Function.apply` will throw an error.
  Expect.throws<NoSuchMethodError>(
    () => Function.apply((runtimeTrue ? f : (() {})), [], {Symbol('a'): 123}),
  );

  // `const` symbols will work as before.
  Function.apply((runtimeTrue ? f : (() {})), [], {#a: 123});
}
