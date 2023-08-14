// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

// Test of parameterized types with invalid bounds.

abstract class J<T> {}

abstract class I<T extends num> {}

class A<T> implements I<T>, J<T> {}
//                    ^
// [cfe] Type argument 'T' doesn't conform to the bound 'num' of the type variable 'T' on 'I'.
//                      ^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

main() {
  // We are only interested in the instance creation, hence
  // the result is assigned to `dynamic`.
  dynamic a = new A<String>();
}
