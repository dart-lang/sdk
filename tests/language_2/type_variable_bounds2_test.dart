// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test of parameterized types with invalid bounds.

abstract class J<T> {}

abstract class I<T extends num> {}

class A</*@compile-error=unspecified*/T> implements I<T>, J<T> {}

main() {
  // We are only interested in the instance creation, hence
  // the result is assigned to `dynamic`.
  dynamic a = /*@compile-error=unspecified*/ new A<String>();
}