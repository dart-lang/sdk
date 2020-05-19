// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type parameters in generic methods can be used in is-expressions.

library generic_methods_simple_is_expression_test;

import "package:expect/expect.dart";

bool fun<T>(int n) {
  return n is T;
}

main() {
  Expect.isTrue(fun<int>(42));
  Expect.isFalse(fun<String>(42));
}
