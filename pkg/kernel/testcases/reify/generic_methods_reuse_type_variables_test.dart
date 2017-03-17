// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type parameter can be passed as a type argument in a definition of
// a local variable, and that this local variable is correctly constructed.

library generic_methods_reuse_type_variables_test;

import "test_base.dart";

int fun<T extends String>(T t) {
  List<T> list = <T>[t, t, t];
  expectTrue(list is List<String>);
  expectTrue(list is! List<int>);
  return list.length;
}

main() {
  expectTrue(fun<String>("foo") == 3);
}
