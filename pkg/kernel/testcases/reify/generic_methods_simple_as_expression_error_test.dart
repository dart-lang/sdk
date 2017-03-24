// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type parameters in generic methods can be used in as-expressions,
// and that an exception is thrown if the cast can't be made.

library generic_methods_simple_as_expression_error_test;

import "test_base.dart";

T cast<T>(dynamic obj) {
  return obj as T;
}

main() {
  expectThrows(() => cast<String>(42), (e) => e is CastError);
}
